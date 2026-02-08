# frozen_string_literal: true

module Attractor
  module LLM
    class StreamAccumulator
      attr_reader :id, :model, :usage, :finish_reason

      def initialize
        @id = nil
        @model = nil
        @content_parts = []
        @current_text = +''
        @current_tool_calls = {}
        @current_thinking = +''
        @usage = Usage::ZERO
        @finish_reason = nil
      end

      def accumulate(event)
        case event.type
        when :message_start
          @id = event.data[:id]
          @model = event.data[:model]
        when :content_delta
          @current_text << (event.data[:text] || '')
        when :tool_call_delta
          tc_id = event.data[:id] || event.data[:index].to_s
          @current_tool_calls[tc_id] ||= { id: tc_id, name: '', arguments_json: +'' }
          @current_tool_calls[tc_id][:name] = event.data[:name] if event.data[:name]
          @current_tool_calls[tc_id][:arguments_json] << (event.data[:arguments] || '')
        when :thinking_delta
          @current_thinking << (event.data[:text] || '')
        when :usage_update
          @usage = Usage.new(**event.data.slice(:input_tokens, :output_tokens,
                                                :cache_read_tokens, :cache_write_tokens, :reasoning_tokens)
            .transform_values { |v| v || 0 })
        when :message_end
          @finish_reason = event.data[:finish_reason]
        end

        self
      end

      def to_response
        parts = build_content_parts
        Response.new(
          id: @id,
          model: @model,
          content: parts,
          usage: @usage,
          finish_reason: @finish_reason
        )
      end

      private

      def build_content_parts
        parts = []
        parts << ContentPart.thinking(text: @current_thinking) unless @current_thinking.empty?
        parts << ContentPart.text(@current_text) unless @current_text.empty?
        @current_tool_calls.each_value do |tc|
          args = parse_arguments(tc[:arguments_json])
          parts << ContentPart.tool_use(id: tc[:id], name: tc[:name], input: args)
        end
        parts
      end

      def parse_arguments(json_str)
        return {} if json_str.empty?

        JSON.parse(json_str, symbolize_names: false)
      rescue JSON::ParserError
        { '_raw' => json_str }
      end
    end
  end
end
