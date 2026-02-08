# frozen_string_literal: true

module Attractor
  module Pipeline
    module Interviewer
      module Base
        def ask(question, node:, context:)
          raise NotImplementedError
        end
      end
    end
  end
end
