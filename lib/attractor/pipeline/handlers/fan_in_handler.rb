# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class FanInHandler
        include Base

        def handler_type = :fan_in

        def handle(node, context, engine)
          # Collect outputs from all incoming branches
          incoming_edges = engine.graph.edges_to(node.id)
          branch_outputs = incoming_edges.filter_map do |edge|
            key = "#{edge.from}.output"
            context[key] || context.get("#{node.id}.branch.#{edge.from}")
          end

          combined = branch_outputs.join("\n---\n")
          updates = { "#{node.id}.output" => combined }

          Outcome.success(output: combined, updates: updates)
        end
      end
    end
  end
end
