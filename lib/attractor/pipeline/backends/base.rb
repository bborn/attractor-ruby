# frozen_string_literal: true

module Attractor
  module Pipeline
    module Backends
      module Base
        def generate(prompt:, node:, context:)
          raise NotImplementedError
        end
      end
    end
  end
end
