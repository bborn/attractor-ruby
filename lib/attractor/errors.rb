# frozen_string_literal: true

module Attractor
  # Base error for all Attractor errors
  class Error < StandardError; end

  module LLM
    # Base error for all LLM SDK errors
    class SDKError < Attractor::Error
      attr_reader :status_code, :provider, :raw_body

      def initialize(message = nil, status_code: nil, provider: nil, raw_body: nil)
        @status_code = status_code
        @provider = provider
        @raw_body = raw_body
        super(message)
      end

      def retryable?
        false
      end
    end

    class AuthenticationError < SDKError; end

    class RateLimitError < SDKError
      attr_reader :retry_after

      def initialize(message = nil, retry_after: nil, **kwargs)
        @retry_after = retry_after
        super(message, **kwargs)
      end

      def retryable? = true
    end

    class APIError < SDKError
      def retryable?
        status_code.nil? || status_code >= 500
      end
    end

    class TimeoutError < SDKError
      def retryable? = true
    end

    class ConnectionError < SDKError
      def retryable? = true
    end

    class InvalidRequestError < SDKError; end
    class ModelNotFoundError < SDKError; end
    class ContentFilterError < SDKError; end

    class StreamError < SDKError
      def retryable? = true
    end

    class ProviderError < SDKError
      def retryable?
        status_code.nil? || status_code >= 500
      end
    end
  end

  module Agent
    class AgentError < Attractor::Error; end
    class LoopDetectedError < AgentError; end
    class ToolExecutionError < AgentError; end
    class SessionLimitError < AgentError; end
  end

  module Pipeline
    class PipelineError < Attractor::Error; end
    class ParseError < PipelineError; end
    class ValidationError < PipelineError; end
    class ExecutionError < PipelineError; end
    class CheckpointError < PipelineError; end
    class GoalGateError < ExecutionError; end
  end
end
