# frozen_string_literal: true

module Attractor
  module Pipeline
    module Transforms
      class Preamble
        include Base

        def initialize(fidelity_resolver:, previous_outputs: [])
          @fidelity_resolver = fidelity_resolver
          @previous_outputs = previous_outputs
        end

        def apply(graph, context)
          graph.nodes.each do |node|
            next unless node.type == :codergen

            fidelity = @fidelity_resolver.resolve(node, graph)
            preamble = @fidelity_resolver.build_preamble(fidelity, context, @previous_outputs)
            next unless preamble

            existing_prompt = node.attributes['prompt'] || ''
            node.attributes['prompt'] = "#{preamble}\n\n#{existing_prompt}"
          end
          graph
        end
      end
    end
  end
end
