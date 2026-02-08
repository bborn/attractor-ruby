# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class ConditionalHandler
        include Base

        def handler_type = :conditional

        def handle(node, _context, _engine)
          # Conditional nodes are pass-through routing points.
          # Edge selection handles the actual branching logic.
          Outcome.success(output: "conditional:#{node.id}")
        end
      end
    end
  end
end
