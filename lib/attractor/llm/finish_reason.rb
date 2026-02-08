# frozen_string_literal: true

module Attractor
  module LLM
    class FinishReason
      CANONICAL = %i[end_turn tool_use max_tokens content_filter error].freeze

      attr_reader :canonical, :raw

      def initialize(canonical, raw: nil)
        raise ArgumentError, "Unknown canonical reason: #{canonical}" unless CANONICAL.include?(canonical)

        @canonical = canonical
        @raw = raw || canonical.to_s
      end

      def stop? = canonical == :end_turn
      def tool_use? = canonical == :tool_use
      def truncated? = canonical == :max_tokens
      def error? = canonical == :error
      def content_filter? = canonical == :content_filter

      def to_s = raw
      def to_sym = canonical

      def ==(other)
        case other
        when FinishReason then canonical == other.canonical
        when Symbol then canonical == other
        when String then raw == other
        else false
        end
      end

      # Provider-specific mapping
      PROVIDER_MAP = {
        # Anthropic
        'end_turn' => :end_turn,
        'tool_use' => :tool_use,
        'max_tokens' => :max_tokens,
        'stop_sequence' => :end_turn,
        # OpenAI
        'stop' => :end_turn,
        'tool_calls' => :tool_use,
        'length' => :max_tokens,
        'content_filter' => :content_filter,
        # Gemini
        'STOP' => :end_turn,
        'MAX_TOKENS' => :max_tokens,
        'SAFETY' => :content_filter,
        'RECITATION' => :content_filter
      }.freeze

      def self.from_provider(raw_reason)
        canonical = PROVIDER_MAP[raw_reason] || :error
        new(canonical, raw: raw_reason)
      end
    end
  end
end
