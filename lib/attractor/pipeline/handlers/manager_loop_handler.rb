# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class ManagerLoopHandler
        include Base

        def handler_type = :manager_loop

        def handle(node, context, engine)
          max_iterations = (node['max_iterations'] || 10).to_i
          child_pipeline_source = node['pipeline'] || node.prompt
          unless child_pipeline_source
            return Outcome.error(error_message: "Manager loop '#{node.id}' has no pipeline defined")
          end

          iteration = 0
          last_output = nil

          while iteration < max_iterations
            iteration += 1
            child_context = context.clone
            child_context['iteration'] = iteration.to_s
            child_context['previous_output'] = last_output.to_s if last_output

            child_graph = Parser.new(child_pipeline_source).parse
            child_engine = Engine.new(
              graph: child_graph,
              backend: engine.backend,
              interviewer: engine.interviewer,
              context: child_context,
              execution_env: engine.execution_env
            )
            result = child_engine.run

            last_output = result[:output]

            # Check completion condition
            if result[:status] == :success
              completion_condition = node['completion_condition']
              break unless completion_condition

              evaluator = ConditionEvaluator.new(context: child_context)
              break if evaluator.evaluate(completion_condition)

            # No condition = single iteration

            else
              return Outcome.fail(
                error_message: "Manager loop iteration #{iteration} failed: #{result[:error]}",
                output: last_output
              )
            end
          end

          updates = { "#{node.id}.output" => last_output, "#{node.id}.iterations" => iteration.to_s }
          Outcome.success(output: last_output, updates: updates)
        end
      end
    end
  end
end
