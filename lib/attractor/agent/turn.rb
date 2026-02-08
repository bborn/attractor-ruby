# frozen_string_literal: true

module Attractor
  module Agent
    module Turn
      class User
        attr_reader :message

        def initialize(message)
          @message = message
        end

        def type = :user
      end

      class Assistant
        attr_reader :response

        def initialize(response)
          @response = response
        end

        def type = :assistant
      end

      class ToolResults
        attr_reader :results

        def initialize(results)
          @results = results
        end

        def type = :tool_results
      end

      class Steering
        attr_reader :content

        def initialize(content)
          @content = content
        end

        def type = :steering
      end
    end
  end
end
