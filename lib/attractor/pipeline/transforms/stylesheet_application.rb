# frozen_string_literal: true

module Attractor
  module Pipeline
    module Transforms
      class StylesheetApplication
        include Base

        def apply(graph, _context)
          stylesheet_source = graph.graph_attributes['stylesheet']
          return graph unless stylesheet_source

          stylesheet = Stylesheet.parse(stylesheet_source)
          graph.nodes.each do |node|
            resolved = stylesheet.resolve(node)
            resolved.each do |key, value|
              # Stylesheet properties don't override explicit node attributes
              node.attributes[key] ||= value
            end
          end
          graph
        end
      end
    end
  end
end
