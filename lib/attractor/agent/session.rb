# frozen_string_literal: true

module Attractor
  module Agent
    class Session
      attr_reader :config, :env, :events, :messages, :usage

      def initialize(client:, config: SessionConfig.new, env: nil, profile: nil)
        @client = client
        @config = config
        @env = env || ExecutionEnv::Local.new
        @profile = profile || resolve_profile
        @registry = @profile.build_registry
        @events = EventEmitter.new
        @loop_detector = LoopDetector.new(
          window: config.loop_detection_window,
          threshold: config.loop_detection_threshold
        )
        @messages = []
        @usage = LLM::Usage::ZERO
        @turn_count = 0
        @steering_queue = []
        @subagent_manager = SubagentManager.new
        @system_prompt = SystemPromptBuilder.new(
          env: @env, config: config, profile: @profile
        ).build
      end

      def process_input(input)
        @messages << LLM::Message.user(input)
        @events.emit(:session_start, { input: input })

        loop do
          break if @turn_count >= config.max_turns

          inject_steering if config.enable_steering && @steering_queue.any?

          @turn_count += 1
          @events.emit(:turn_start, { turn: @turn_count })

          response = call_llm
          @messages << response.to_message
          @usage += response.usage

          @events.emit(:llm_response, { response: response })

          if response.has_tool_calls?
            tool_results = execute_tool_calls(response.tool_calls)
            @messages << LLM::Message.new(role: :user, content: tool_results)
            @events.emit(:turn_end, { turn: @turn_count, has_tool_calls: true })
          else
            @events.emit(:turn_end, { turn: @turn_count, has_tool_calls: false })
            @events.emit(:session_end, { result: response.text, usage: @usage })
            return response.text
          end
        end

        raise SessionLimitError, "Exceeded max turns (#{config.max_turns})"
      end

      def add_steering(content)
        @steering_queue << content
      end

      private

      def call_llm
        request = LLM::Request.new(
          model: config.model,
          messages: @messages,
          system: @system_prompt,
          tools: @registry.to_llm_tools,
          temperature: config.temperature,
          max_tokens: config.max_tokens
        )
        @events.emit(:llm_request_start, { model: config.model })
        @client.complete(request)
      end

      def execute_tool_calls(tool_calls)
        tool_calls.map do |tc|
          @events.emit(:tool_call_start, { name: tc.name, arguments: tc.input })
          @loop_detector.record(tc.name, tc.input.hash.to_s)

          if @loop_detector.loop_detected?
            @events.emit(:loop_detected, { pattern: @loop_detector.pattern_description })
            raise LoopDetectedError, "Loop detected: #{@loop_detector.pattern_description}"
          end

          result = begin
            @registry.execute(tc.name, tc.input, env: @env)
          rescue StandardError => e
            @events.emit(:error, { tool: tc.name, error: e.message })
            "Error: #{e.message}"
          end

          @events.emit(:tool_call_end, { name: tc.name, result_length: result.to_s.length })
          LLM::ContentPart.tool_result(tool_use_id: tc.id, content: result.to_s)
        end
      end

      def inject_steering
        content = @steering_queue.shift
        @messages << LLM::Message.user("[STEERING] #{content}")
        @events.emit(:steering_injected, { content: content })
      end

      def resolve_profile
        case config.provider
        when :anthropic then ProviderProfiles::AnthropicProfile.new
        when :openai then ProviderProfiles::OpenAIProfile.new
        when :gemini then ProviderProfiles::GeminiProfile.new
        else ProviderProfiles::AnthropicProfile.new
        end
      end
    end
  end
end
