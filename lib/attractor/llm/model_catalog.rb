# frozen_string_literal: true

module Attractor
  module LLM
    class ModelCatalog
      ModelInfo = Struct.new(:id, :provider, :context_window, :max_output_tokens,
                             :supports_tools, :supports_vision, :supports_thinking,
                             keyword_init: true)

      MODELS = {
        # Anthropic
        'claude-sonnet-4-5-20250514' => ModelInfo.new(
          id: 'claude-sonnet-4-5-20250514', provider: :anthropic,
          context_window: 200_000, max_output_tokens: 8192,
          supports_tools: true, supports_vision: true, supports_thinking: true
        ),
        'claude-opus-4-20250514' => ModelInfo.new(
          id: 'claude-opus-4-20250514', provider: :anthropic,
          context_window: 200_000, max_output_tokens: 32_000,
          supports_tools: true, supports_vision: true, supports_thinking: true
        ),
        'claude-haiku-3-5-20241022' => ModelInfo.new(
          id: 'claude-haiku-3-5-20241022', provider: :anthropic,
          context_window: 200_000, max_output_tokens: 8192,
          supports_tools: true, supports_vision: true, supports_thinking: false
        ),
        # OpenAI
        'gpt-4o' => ModelInfo.new(
          id: 'gpt-4o', provider: :openai,
          context_window: 128_000, max_output_tokens: 16_384,
          supports_tools: true, supports_vision: true, supports_thinking: false
        ),
        'o3-mini' => ModelInfo.new(
          id: 'o3-mini', provider: :openai,
          context_window: 200_000, max_output_tokens: 100_000,
          supports_tools: true, supports_vision: false, supports_thinking: true
        ),
        # Gemini
        'gemini-2.5-pro' => ModelInfo.new(
          id: 'gemini-2.5-pro', provider: :gemini,
          context_window: 1_000_000, max_output_tokens: 65_536,
          supports_tools: true, supports_vision: true, supports_thinking: true
        ),
        'gemini-2.5-flash' => ModelInfo.new(
          id: 'gemini-2.5-flash', provider: :gemini,
          context_window: 1_000_000, max_output_tokens: 65_536,
          supports_tools: true, supports_vision: true, supports_thinking: true
        )
      }.freeze

      def self.lookup(model_id)
        MODELS[model_id]
      end

      def self.provider_for(model_id)
        info = MODELS[model_id]
        return info.provider if info

        # Infer provider from model ID prefix
        case model_id
        when /^claude/ then :anthropic
        when /^gpt|^o\d/ then :openai
        when /^gemini/ then :gemini
        else
          raise ModelNotFoundError, "Unknown model: #{model_id}"
        end
      end

      def self.all
        MODELS.values
      end
    end
  end
end
