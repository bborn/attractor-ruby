# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class StartHandler
        include Base

        def handler_type = :start

        def handle(_node, _context, _engine)
          Outcome.success(output: 'Pipeline started')
        end
      end
    end
  end
end
