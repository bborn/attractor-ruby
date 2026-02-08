# frozen_string_literal: true

module Attractor
  module LLM
    # High-level generate function with automatic tool execution loop
    module Generate
      def self.call(client:, request:, max_tool_rounds: 10)
        messages = request.messages.dup
        tools_by_name = (request.tools || []).each_with_object({}) { |t, h| h[t.name] = t }
        total_usage = Usage::ZERO
        round = 0

        loop do
          current_request = request.with(messages: messages)
          response = client.complete(current_request)
          total_usage += response.usage
          round += 1

          if response.has_tool_calls? && round < max_tool_rounds
            messages << response.to_message
            tool_results = execute_tool_calls(response.tool_calls, tools_by_name)
            messages << Message.new(role: :user, content: tool_results)
          else
            return Response.new(
              id: response.id,
              model: response.model,
              content: response.content,
              usage: total_usage,
              finish_reason: response.finish_reason,
              raw: response.raw
            )
          end
        end
      end

      def self.execute_tool_calls(tool_calls, tools_by_name)
        tool_calls.map do |tc|
          tool = tools_by_name[tc.name]
          if tool
            begin
              result = tool.execute(tc.input)
              ContentPart.tool_result(tool_use_id: tc.id, content: result.to_s)
            rescue StandardError => e
              ContentPart.tool_result(tool_use_id: tc.id, content: "Error: #{e.message}", is_error: true)
            end
          else
            ContentPart.tool_result(tool_use_id: tc.id, content: "Unknown tool: #{tc.name}", is_error: true)
          end
        end
      end

      private_class_method :execute_tool_calls
    end
  end
end
