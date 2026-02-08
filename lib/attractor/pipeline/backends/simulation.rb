# frozen_string_literal: true

module Attractor
  module Pipeline
    module Backends
      class Simulation
        include Base

        def initialize(responses: {}, default_response: 'Simulated response')
          @responses = responses
          @default_response = default_response
        end

        def generate(prompt:, node:, context:)
          # Check for node-specific response first
          if @responses.key?(node.id)
            response = @responses[node.id]
            return response.is_a?(Proc) ? response.call(prompt, context) : response
          end

          # Check for prompt pattern match
          @responses.each do |pattern, response|
            next unless pattern.is_a?(Regexp) && pattern.match?(prompt)

            return response.is_a?(Proc) ? response.call(prompt, context) : response
          end

          @default_response
        end
      end
    end
  end
end
