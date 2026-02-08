# frozen_string_literal: true

module Attractor
  module Agent
    class LoopDetector
      DEFAULT_WINDOW = 6
      DEFAULT_THRESHOLD = 3

      def initialize(window: DEFAULT_WINDOW, threshold: DEFAULT_THRESHOLD)
        @window = window
        @threshold = threshold
        @history = []
      end

      def record(tool_name, arguments_hash)
        signature = "#{tool_name}:#{arguments_hash}"
        @history << signature
        @history.shift if @history.length > @window * 2
      end

      def loop_detected?
        return false if @history.length < @threshold

        recent = @history.last(@window)
        # Check for exact repetition of the last call
        last = recent.last
        count = recent.count(last)
        count >= @threshold
      end

      def reset
        @history.clear
      end

      def pattern_description
        return nil unless loop_detected?

        last = @history.last
        "Repeated call: #{last}"
      end
    end
  end
end
