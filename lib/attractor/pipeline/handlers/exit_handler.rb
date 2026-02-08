# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class ExitHandler
        include Base

        def handler_type = :exit

        def handle(_node, _context, _engine)
          Outcome.success(output: 'Pipeline completed')
        end
      end
    end
  end
end
