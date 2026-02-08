# frozen_string_literal: true

module Attractor
  module Pipeline
    module Interviewer
      class AutoApprove
        include Base

        def initialize(response: 'approved')
          @response = response
        end

        def ask(_question, node:, context:)
          @response
        end
      end
    end
  end
end
