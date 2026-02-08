# frozen_string_literal: true

module Attractor
  module LLM
    class Response
      attr_reader :id, :model, :content, :usage, :finish_reason, :raw

      def initialize(id:, model:, content:, usage:, finish_reason:, raw: nil)
        @id = id
        @model = model
        @content = content
        @usage = usage
        @finish_reason = finish_reason
        @raw = raw
      end

      def text
        content.select { |p| p.type == :text }.map(&:to_s).join
      end

      def tool_calls
        content.select { |p| p.type == :tool_use }
      end

      def has_tool_calls?
        content.any? { |p| p.type == :tool_use }
      end

      def thinking
        content.select { |p| p.type == :thinking }.map(&:text).join
      end

      def stop? = finish_reason&.stop?
      def tool_use? = finish_reason&.tool_use?
      def truncated? = finish_reason&.truncated?

      def to_message
        Message.new(role: :assistant, content: content)
      end
    end
  end
end
