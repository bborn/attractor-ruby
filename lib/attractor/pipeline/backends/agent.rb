# frozen_string_literal: true

module Attractor
  module Pipeline
    module Backends
      class AgentBackend
        include Base

        def initialize(client:, default_model: 'claude-sonnet-4-5-20250514', env: nil)
          @client = client
          @default_model = default_model
          @env = env
        end

        def generate(prompt:, node:, context:)
          config = Agent::SessionConfig.new(
            model: node.model || @default_model,
            max_turns: (node['max_turns'] || 50).to_i,
            max_tokens: (node['max_tokens'] || 8192).to_i,
            temperature: node['temperature']&.to_f || 0
          )

          env = @env || Agent::ExecutionEnv::Local.new
          session = Agent::Session.new(client: @client, config: config, env: env)
          session.process_input(prompt)
        end
      end
    end
  end
end
