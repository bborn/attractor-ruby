# frozen_string_literal: true

module Attractor
  module Pipeline
    module Transforms
      module Base
        def apply(graph, context)
          raise NotImplementedError
        end
      end
    end
  end
end
