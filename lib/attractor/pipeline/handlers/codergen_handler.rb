# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class CodergenHandler
        include Base

        def handler_type = :codergen

        def initialize(backend: nil)
          @backend = backend
        end

        def handle(node, context, engine)
          backend = @backend || engine.backend
          prompt = node.prompt || node.label
          prompt = expand_context_vars(prompt, context)

          result = backend.generate(prompt: prompt, node: node, context: context)

          updates = {}
          updates["#{node.id}.output"] = result

          Outcome.success(output: result, updates: updates)
        rescue StandardError => e
          Outcome.error(error_message: "Codergen failed: #{e.message}")
        end

        private

        def expand_context_vars(text, context)
          text.gsub(/\$\{?(\w+)\}?/) do
            var = ::Regexp.last_match(1)
            context[var]&.to_s || ::Regexp.last_match(0)
          end
        end
      end
    end
  end
end
