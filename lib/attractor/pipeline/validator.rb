# frozen_string_literal: true

module Attractor
  module Pipeline
    class Validator
      def initialize(graph)
        @graph = graph
        @diagnostics = []
      end

      def validate
        @diagnostics = []
        check_single_start
        check_at_least_one_exit
        check_start_has_no_incoming
        check_exit_has_no_outgoing
        check_all_nodes_reachable
        check_no_orphan_edges
        check_codergen_has_prompt
        check_parallel_has_fan_in
        check_conditional_has_edges
        check_fan_in_incoming_count
        check_edge_targets_exist
        check_no_self_loops
        @diagnostics
      end

      def valid?
        validate.none?(&:error?)
      end

      private

      def check_single_start
        starts = @graph.nodes.select { |n| n.type == :start }
        if starts.empty?
          add(:no_start, :error, 'Graph has no start node (shape=Mdiamond)')
        elsif starts.length > 1
          add(:multiple_starts, :error, "Graph has #{starts.length} start nodes, expected 1")
        end
      end

      def check_at_least_one_exit
        exits = @graph.nodes.select { |n| n.type == :exit }
        add(:no_exit, :error, 'Graph has no exit node (shape=Msquare)') if exits.empty?
      end

      def check_start_has_no_incoming
        @graph.nodes.select { |n| n.type == :start }.each do |start|
          if @graph.edges_to(start.id).any?
            add(:start_has_incoming, :error, "Start node '#{start.id}' has incoming edges", node_id: start.id)
          end
        end
      end

      def check_exit_has_no_outgoing
        @graph.nodes.select { |n| n.type == :exit }.each do |exit_node|
          if @graph.edges_from(exit_node.id).any?
            add(:exit_has_outgoing, :error, "Exit node '#{exit_node.id}' has outgoing edges", node_id: exit_node.id)
          end
        end
      end

      def check_all_nodes_reachable
        start = @graph.start_node
        return unless start

        visited = Set.new
        queue = [start.id]
        while (current = queue.shift)
          next if visited.include?(current)

          visited << current
          @graph.edges_from(current).each { |e| queue << e.to }
        end

        @graph.nodes.each do |node|
          unless visited.include?(node.id)
            add(:unreachable_node, :warning, "Node '#{node.id}' is not reachable from start", node_id: node.id)
          end
        end
      end

      def check_no_orphan_edges
        node_ids = Set.new(@graph.node_ids)
        @graph.edges.each do |edge|
          add(:orphan_edge, :error, "Edge from unknown node '#{edge.from}'") unless node_ids.include?(edge.from)
          add(:orphan_edge, :error, "Edge to unknown node '#{edge.to}'") unless node_ids.include?(edge.to)
        end
      end

      def check_codergen_has_prompt
        @graph.nodes.select { |n| n.type == :codergen }.each do |node|
          unless node.prompt || node.label != node.id
            add(:codergen_no_prompt, :warning, "Codergen node '#{node.id}' has no prompt", node_id: node.id)
          end
        end
      end

      def check_parallel_has_fan_in
        @graph.nodes.select { |n| n.type == :parallel }.each do |parallel|
          targets = @graph.edges_from(parallel.id).map(&:to)
          # Check that downstream eventually reaches a fan_in
          has_fan_in = targets.any? do |target_id|
            downstream_has_type?(target_id, :fan_in, Set.new)
          end
          unless has_fan_in
            add(:parallel_no_fan_in, :warning, "Parallel node '#{parallel.id}' has no downstream fan_in",
                node_id: parallel.id)
          end
        end
      end

      def check_conditional_has_edges
        @graph.nodes.select { |n| n.type == :conditional }.each do |node|
          if @graph.edges_from(node.id).empty?
            add(:conditional_no_edges, :error, "Conditional node '#{node.id}' has no outgoing edges", node_id: node.id)
          end
        end
      end

      def check_fan_in_incoming_count
        @graph.nodes.select { |n| n.type == :fan_in }.each do |node|
          incoming = @graph.edges_to(node.id)
          if incoming.length < 2
            add(:fan_in_few_inputs, :warning, "Fan-in node '#{node.id}' has only #{incoming.length} incoming edge(s)",
                node_id: node.id)
          end
        end
      end

      def check_edge_targets_exist
        node_ids = Set.new(@graph.node_ids)
        @graph.edges.each do |edge|
          add(:missing_target, :error, "Edge target '#{edge.to}' does not exist") unless node_ids.include?(edge.to)
          add(:missing_source, :error, "Edge source '#{edge.from}' does not exist") unless node_ids.include?(edge.from)
        end
      end

      def check_no_self_loops
        @graph.edges.each do |edge|
          add(:self_loop, :warning, "Self-loop on node '#{edge.from}'", node_id: edge.from) if edge.from == edge.to
        end
      end

      def downstream_has_type?(node_id, type, visited)
        return false if visited.include?(node_id)

        visited << node_id

        node = @graph.node(node_id)
        return true if node&.type == type

        @graph.edges_from(node_id).any? do |edge|
          downstream_has_type?(edge.to, type, visited)
        end
      end

      def add(rule, severity, message, node_id: nil)
        @diagnostics << Diagnostic.new(rule: rule, severity: severity, message: message, node_id: node_id)
      end
    end
  end
end
