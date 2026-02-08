# frozen_string_literal: true

module Attractor
  module Pipeline
    module Transforms
      class VariableExpansion
        include Base

        def apply(graph, context)
          graph.nodes.each do |node|
            node.attributes.each do |key, value|
              next unless value.is_a?(String) && value.include?('$')

              node.attributes[key] = expand(value, context)
            end
          end
          graph
        end

        private

        def expand(text, context)
          text.gsub(/\$\{?(\w+)\}?/) do |_match|
            var_name = ::Regexp.last_match(1)
            context[var_name]&.to_s || _match
          end
        end
      end
    end
  end
end
