# frozen_string_literal: true

module Attractor
  module Pipeline
    module Interviewer
      class Queue
        include Base

        def initialize(answers = [])
          @answers = answers.dup
        end

        def ask(_question, node:, context:)
          raise ExecutionError, 'No more answers in queue' if @answers.empty?

          @answers.shift
        end

        def remaining
          @answers.length
        end
      end
    end
  end
end
