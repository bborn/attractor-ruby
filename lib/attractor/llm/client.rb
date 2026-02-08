# frozen_string_literal: true

module Attractor
  module LLM
    class Client
      attr_reader :retry_policy

      def initialize(providers: {}, retry_policy: RetryPolicy::DEFAULT)
        @providers = {}
        @retry_policy = retry_policy
        @middleware = []

        providers.each do |name, config|
          register_provider(name, config)
        end
      end

      def register_provider(name, config)
        adapter = case name.to_sym
                  when :anthropic
                    Providers::AnthropicAdapter.new(**config)
                  when :openai
                    Providers::OpenAIAdapter.new(**config)
                  when :gemini
                    Providers::GeminiAdapter.new(**config)
                  else
                    raise ArgumentError, "Unknown provider: #{name}"
                  end
        @providers[name.to_sym] = adapter
      end

      def use(&middleware_block)
        @middleware << middleware_block
        self
      end

      def complete(request)
        request = apply_middleware(request)
        adapter = adapter_for(request.model)
        retry_policy.execute { adapter.complete(request) }
      end

      def stream(request, &block)
        request = apply_middleware(request)
        adapter = adapter_for(request.model)
        retry_policy.execute { adapter.stream(request, &block) }
      end

      private

      def adapter_for(model)
        provider = ModelCatalog.provider_for(model)
        @providers[provider] || raise(InvalidRequestError, "No provider configured for #{provider} (model: #{model})")
      end

      def apply_middleware(request)
        @middleware.reduce(request) { |req, mw| mw.call(req) }
      end
    end
  end
end
