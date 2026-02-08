# frozen_string_literal: true

module Attractor
  module LLM
    class ToolResult
      attr_reader :tool_call_id, :content, :is_error

      def initialize(tool_call_id:, content:, is_error: false)
        @tool_call_id = tool_call_id
        @content = content
        @is_error = is_error
      end

      def error? = is_error

      def to_h
        { tool_call_id: tool_call_id, content: content, is_error: is_error }
      end
    end
  end
end
