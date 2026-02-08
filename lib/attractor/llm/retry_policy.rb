# frozen_string_literal: true

module Attractor
  module LLM
    class RetryPolicy
      attr_reader :max_retries, :base_delay, :max_delay, :jitter

      def initialize(max_retries: 3, base_delay: 1.0, max_delay: 60.0, jitter: true)
        @max_retries = max_retries
        @base_delay = base_delay
        @max_delay = max_delay
        @jitter = jitter
      end

      def should_retry?(error, attempt)
        return false unless attempt < max_retries
        return false unless error.respond_to?(:retryable?) && error.retryable?

        true
      end

      def delay_for(attempt)
        delay = base_delay * (2**attempt)
        delay = [delay, max_delay].min
        delay *= rand(0.5..1.0) if jitter
        delay
      end

      def execute
        attempt = 0
        begin
          yield
        rescue SDKError => e
          if should_retry?(e, attempt)
            sleep_duration = if e.is_a?(RateLimitError) && e.retry_after
                               e.retry_after
                             else
                               delay_for(attempt)
                             end
            sleep(sleep_duration)
            attempt += 1
            retry
          end
          raise
        end
      end

      NONE = new(max_retries: 0).freeze
      DEFAULT = new.freeze
    end
  end
end
