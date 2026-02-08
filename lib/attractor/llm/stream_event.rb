# frozen_string_literal: true

module Attractor
  module LLM
    class StreamEvent
      TYPES = %i[
        message_start message_end
        content_delta tool_call_delta
        thinking_delta usage_update error
      ].freeze

      attr_reader :type, :data

      def initialize(type:, data: {})
        @type = type
        @data = data
      end

      def content_delta? = type == :content_delta
      def tool_call_delta? = type == :tool_call_delta
      def thinking_delta? = type == :thinking_delta
      def usage_update? = type == :usage_update
      def message_start? = type == :message_start
      def message_end? = type == :message_end
      def error? = type == :error
    end
  end
end
