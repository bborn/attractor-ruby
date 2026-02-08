# frozen_string_literal: true

module Attractor
  module Pipeline
    module Interviewer
      class Recording
        include Base

        attr_reader :recordings

        def initialize(delegate:)
          @delegate = delegate
          @recordings = []
        end

        def ask(question, node:, context:)
          response = @delegate.ask(question, node: node, context: context)
          @recordings << { question: question, response: response, node_id: node.id }
          response
        end
      end
    end
  end
end
