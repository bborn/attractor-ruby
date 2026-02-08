# frozen_string_literal: true

module Attractor
  module LLM
    class Request
      attr_reader :model, :messages, :system, :tools, :temperature,
                  :max_tokens, :stop_sequences, :tool_choice, :stream,
                  :metadata

      def initialize(model:, messages:, system: nil, tools: nil,
                     temperature: nil, max_tokens: nil, stop_sequences: nil,
                     tool_choice: nil, stream: false, metadata: {})
        @model = model
        @messages = messages
        @system = system
        @tools = tools
        @temperature = temperature
        @max_tokens = max_tokens
        @stop_sequences = stop_sequences
        @tool_choice = tool_choice
        @stream = stream
        @metadata = metadata
      end

      def stream? = stream

      def with(**overrides)
        self.class.new(
          model: overrides.fetch(:model, model),
          messages: overrides.fetch(:messages, messages),
          system: overrides.fetch(:system, system),
          tools: overrides.fetch(:tools, tools),
          temperature: overrides.fetch(:temperature, temperature),
          max_tokens: overrides.fetch(:max_tokens, max_tokens),
          stop_sequences: overrides.fetch(:stop_sequences, stop_sequences),
          tool_choice: overrides.fetch(:tool_choice, tool_choice),
          stream: overrides.fetch(:stream, stream),
          metadata: overrides.fetch(:metadata, metadata)
        )
      end
    end
  end
end
