# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class WaitHumanHandler
        include Base

        def handler_type = :wait_human

        def handle(node, context, engine)
          interviewer = engine.interviewer
          question = node.prompt || node.label || 'Awaiting human input'
          question = question.sub(/^wait\.human:\s*/i, '')

          response = interviewer.ask(question, node: node, context: context)

          updates = {}
          updates["#{node.id}.response"] = response
          updates['human_approved'] = (response.to_s.downcase != 'reject' && response.to_s.downcase != 'no')

          Outcome.success(output: response, updates: updates)
        end
      end
    end
  end
end
