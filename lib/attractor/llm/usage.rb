# frozen_string_literal: true

module Attractor
  module LLM
    class Usage
      attr_reader :input_tokens, :output_tokens, :cache_read_tokens,
                  :cache_write_tokens, :reasoning_tokens

      def initialize(input_tokens: 0, output_tokens: 0, cache_read_tokens: 0,
                     cache_write_tokens: 0, reasoning_tokens: 0)
        @input_tokens = input_tokens
        @output_tokens = output_tokens
        @cache_read_tokens = cache_read_tokens
        @cache_write_tokens = cache_write_tokens
        @reasoning_tokens = reasoning_tokens
      end

      def total_tokens
        input_tokens + output_tokens
      end

      def +(other)
        self.class.new(
          input_tokens: input_tokens + other.input_tokens,
          output_tokens: output_tokens + other.output_tokens,
          cache_read_tokens: cache_read_tokens + other.cache_read_tokens,
          cache_write_tokens: cache_write_tokens + other.cache_write_tokens,
          reasoning_tokens: reasoning_tokens + other.reasoning_tokens
        )
      end

      def to_h
        {
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          cache_read_tokens: cache_read_tokens,
          cache_write_tokens: cache_write_tokens,
          reasoning_tokens: reasoning_tokens,
          total_tokens: total_tokens
        }
      end

      ZERO = new.freeze
    end
  end
end
