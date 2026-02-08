# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class ToolHandler
        include Base

        def handler_type = :tool

        def handle(node, context, engine)
          command = node['command'] || node.prompt || node.label
          return Outcome.error(error_message: "Tool node '#{node.id}' has no command") unless command

          command = expand_vars(command, context)

          env = engine.execution_env
          if env
            result = env.execute_command(command)
            if result[:success]
              updates = { "#{node.id}.output" => result[:stdout] }
              Outcome.success(output: result[:stdout], updates: updates)
            else
              Outcome.fail(
                output: result[:stderr],
                error_message: "Command failed (exit #{result[:exit_code]}): #{result[:stderr]}"
              )
            end
          else
            Outcome.error(error_message: 'No execution environment configured')
          end
        end

        private

        def expand_vars(text, context)
          text.gsub(/\$\{?(\w+)\}?/) do
            var = ::Regexp.last_match(1)
            context[var]&.to_s || ::Regexp.last_match(0)
          end
        end
      end
    end
  end
end
