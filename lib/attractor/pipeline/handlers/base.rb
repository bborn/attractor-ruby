# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      module Base
        def handle(node, context, engine)
          raise NotImplementedError, "#{self.class}#handle not implemented"
        end

        def handler_type
          raise NotImplementedError
        end
      end
    end
  end
end
