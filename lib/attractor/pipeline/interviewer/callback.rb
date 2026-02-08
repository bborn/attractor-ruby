# frozen_string_literal: true

module Attractor
  module Pipeline
    module Interviewer
      class Callback
        include Base

        def initialize(&block)
          @callback = block
        end

        def ask(question, node:, context:)
          @callback.call(question, node: node, context: context)
        end
      end
    end
  end
end
