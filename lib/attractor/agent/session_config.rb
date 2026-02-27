# frozen_string_literal: true

module Attractor
  module Agent
    class SessionConfig
      attr_accessor :max_turns, :max_tool_calls_per_turn, :command_timeout,
                    :output_truncation_chars, :loop_detection_window,
                    :loop_detection_threshold, :model, :provider,
                    :temperature, :max_tokens, :enable_steering,
                    :project_doc_globs, :message_window_size

      def initialize(**opts)
        @max_turns = opts.fetch(:max_turns, 100)
        @max_tool_calls_per_turn = opts.fetch(:max_tool_calls_per_turn, 25)
        @command_timeout = opts.fetch(:command_timeout, 120)
        @output_truncation_chars = opts.fetch(:output_truncation_chars, 30_000)
        @loop_detection_window = opts.fetch(:loop_detection_window, 6)
        @loop_detection_threshold = opts.fetch(:loop_detection_threshold, 3)
        @model = opts.fetch(:model, 'claude-sonnet-4-5-20250514')
        @provider = opts.fetch(:provider, :anthropic)
        @temperature = opts.fetch(:temperature, 0)
        @max_tokens = opts.fetch(:max_tokens, 8192)
        @enable_steering = opts.fetch(:enable_steering, true)
        @project_doc_globs = opts.fetch(:project_doc_globs, %w[
                                          CLAUDE.md .claude/instructions.md README.md
                                        ])
        # Message window: keep last N turns in API requests to prevent unbounded growth
        # Each turn = 3 messages (user, assistant, tool_results)
        # Default 10 turns = 30 messages = ~100k tokens max
        @message_window_size = opts.fetch(:message_window_size, 10)
      end
    end
  end
end
