# frozen_string_literal: true

module Attractor
  module Pipeline
    module Backends
      class DirectLLM
        include Base

        def initialize(client:, default_model: 'claude-sonnet-4-5-20250514')
          @client = client
          @default_model = default_model
        end

        def generate(prompt:, node:, context:)
          model = node.model || @default_model
          system_prompt = build_system_prompt(node, context)

          request = LLM::Request.new(
            model: model,
            messages: [LLM::Message.user(prompt)],
            system: system_prompt,
            max_tokens: (node['max_tokens'] || 4096).to_i,
            temperature: node['temperature']&.to_f
          )

          response = @client.complete(request)
          response.text
        end

        private

        def build_system_prompt(node, _context)
          parts = []
          parts << node['system'] if node['system']
          parts << "Goal gate: Your output must satisfy this condition: #{node.goal_gate}" if node.goal_gate
          parts.empty? ? nil : parts.join("\n\n")
        end
      end
    end
  end
end
