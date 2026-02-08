# frozen_string_literal: true

module Attractor
  module Pipeline
    class Engine
      attr_reader :graph, :backend, :interviewer, :context, :execution_env, :events

      def initialize(graph:, backend:, interviewer: nil, context: nil,
                     execution_env: nil, handler_registry: nil, checkpoint_dir: nil)
        @graph = graph
        @backend = backend
        @interviewer = interviewer || Interviewer::AutoApprove.new
        @context = context || Context.new
        @execution_env = execution_env
        @handler_registry = handler_registry || Handlers::Registry.default
        @checkpoint_dir = checkpoint_dir
        @events = PipelineEventEmitter.new
        @completed_nodes = Set.new
        @node_outcomes = {}
        @previous_outputs = []
      end

      def run(from_checkpoint: nil)
        if from_checkpoint
          restore_checkpoint(from_checkpoint)
          current_node_id = from_checkpoint.node_id
        else
          current_node_id = graph.start_node&.id
          raise ExecutionError, 'No start node found' unless current_node_id
        end

        events.emit(:pipeline_start, { graph: graph.name })

        loop do
          node = graph.node(current_node_id)
          raise ExecutionError, "Node not found: #{current_node_id}" unless node

          events.emit(:node_enter, { node_id: node.id, type: node.type })

          outcome = execute_node(node)
          @node_outcomes[node.id] = outcome
          @completed_nodes << node.id

          # Apply context updates
          outcome.updates.each { |k, v| @context.set(k, v) }
          @context.set("#{node.id}.status", outcome.status.to_s)

          @previous_outputs << { node: node.id, text: outcome.output.to_s } if outcome.output

          events.emit(:node_exit, { node_id: node.id, outcome: outcome.status })
          save_checkpoint(node.id) if @checkpoint_dir

          # Check for exit node
          if node.type == :exit
            events.emit(:pipeline_end, { status: :success })
            return { status: :success, output: outcome.output, context: @context.to_h }
          end

          # Handle failure with retry
          if outcome.fail? || outcome.error?
            retry_result = handle_retry(node, outcome)
            if retry_result
              outcome = retry_result
              @node_outcomes[node.id] = outcome
              @context.set("#{node.id}.status", outcome.status.to_s)
            else
              events.emit(:pipeline_end, { status: :failed, node: node.id })
              return { status: :failed, error: outcome.error_message, node: node.id, context: @context.to_h }
            end
          end

          # Goal gate enforcement
          if node.goal_gate && outcome.success? && !check_goal_gate(node, outcome)
            events.emit(:goal_gate_fail, { node_id: node.id })
            events.emit(:pipeline_end, { status: :failed, node: node.id })
            return { status: :failed, error: "Goal gate not satisfied for #{node.id}", node: node.id,
                     context: @context.to_h }
          end

          # Select next edge
          next_node_id = select_next_edge(node, outcome)
          unless next_node_id
            events.emit(:pipeline_end, { status: :failed, node: node.id })
            return { status: :failed, error: "No valid edge from #{node.id}", node: node.id, context: @context.to_h }
          end

          events.emit(:edge_selected, { from: node.id, to: next_node_id })
          current_node_id = next_node_id
        end
      end

      # Used by parallel handler to run a branch
      def execute_branch(start_node_id, branch_context)
        node = graph.node(start_node_id)
        return nil unless node

        handler = @handler_registry.lookup(node.type)
        outcome = handler.handle(node, branch_context, self)
        outcome.output
      end

      private

      def execute_node(node)
        # Skip parallel handler's automatic execution of branches -
        # they are handled by the edge selection after parallel completes
        handler = @handler_registry.lookup(node.type)
        handler.handle(node, @context, self)
      rescue StandardError => e
        Outcome.error(error_message: "Handler error for #{node.id}: #{e.message}")
      end

      def select_next_edge(node, outcome)
        edges = graph.edges_from(node.id)
        return nil if edges.empty?

        # 5-step edge selection algorithm
        # Step 1: Exact status match
        status_label = outcome.status.to_s
        exact = edges.find { |e| normalize_label(e.label) == status_label }
        return exact.to if exact && evaluate_edge_condition(exact)

        # Step 2: Condition-based edges
        conditional = edges.select(&:condition)
        conditional.each do |edge|
          return edge.to if evaluate_edge_condition(edge)
        end

        # Step 3: Labeled edges matching outcome
        labeled = edges.select { |e| e.label && normalize_label(e.label) != 'default' }
        match = labeled.find { |e| normalize_label(e.label) == status_label }
        return match.to if match

        # Step 4: Default/fallback edge
        default = edges.find { |e| normalize_label(e.label) == 'default' }
        return default.to if default

        # Step 5: Unlabeled edge (highest weight)
        unlabeled = edges.reject(&:label)
        if unlabeled.any?
          best = unlabeled.max_by(&:weight)
          return best.to
        end

        # Fallback: first edge
        edges.first&.to
      end

      def evaluate_edge_condition(edge)
        condition = edge.condition
        return true unless condition

        last_outcome = @node_outcomes[edge.from]
        evaluator = ConditionEvaluator.new(context: @context, outcome: last_outcome)
        evaluator.evaluate(condition)
      end

      def normalize_label(label)
        return nil unless label

        label.to_s.strip.downcase
      end

      def check_goal_gate(node, outcome)
        evaluator = ConditionEvaluator.new(context: @context, outcome: outcome)
        evaluator.evaluate(node.goal_gate)
      end

      def handle_retry(node, _outcome)
        max_retries = node.retry_limit
        attempt = 0
        while attempt < max_retries
          attempt += 1
          events.emit(:retry_attempt, { node_id: node.id, attempt: attempt })
          sleep(0.1 * attempt) # Simple backoff

          new_outcome = execute_node(node)
          return new_outcome if new_outcome.success?
        end
        nil
      end

      def save_checkpoint(node_id)
        return unless @checkpoint_dir

        checkpoint = Checkpoint.new(
          node_id: node_id,
          context_snapshot: @context.to_h,
          completed_nodes: @completed_nodes.to_a
        )
        path = File.join(@checkpoint_dir, "checkpoint_#{node_id}.json")
        checkpoint.save(path)
        events.emit(:checkpoint_saved, { node_id: node_id, path: path })
      end

      def restore_checkpoint(checkpoint)
        @context = Context.new(checkpoint.context_snapshot)
        @completed_nodes = Set.new(checkpoint.completed_nodes)
        events.emit(:checkpoint_restored, { node_id: checkpoint.node_id })
      end
    end
  end
end
