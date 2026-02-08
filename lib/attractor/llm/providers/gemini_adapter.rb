# frozen_string_literal: true

module Attractor
  module LLM
    module Providers
      class GeminiAdapter
        include BaseAdapter

        DEFAULT_BASE_URL = 'https://generativelanguage.googleapis.com'

        def self.provider_name = :gemini

        def initialize(api_key:, base_url: DEFAULT_BASE_URL)
          @api_key = api_key
          @base_url = base_url
        end

        def complete(request)
          url = "#{base_url}/v1beta/models/#{request.model}:generateContent?key=#{api_key}"
          body = build_body(request)
          raw = http_post(url, headers: default_headers, body: body)
          parse_response(raw, request.model)
        end

        def stream(request, &block)
          url = "#{base_url}/v1beta/models/#{request.model}:streamGenerateContent?alt=sse&key=#{api_key}"
          body = build_body(request)
          accumulator = StreamAccumulator.new

          sse = SSEParser.new do |_event_type, data|
            parsed = JSON.parse(data, symbolize_names: false)
            events = translate_stream_chunk(parsed)
            events.each do |event|
              accumulator.accumulate(event)
              block&.call(event)
            end
          end

          http_post(url, headers: default_headers, body: body) do |chunk|
            sse.feed(chunk)
          end

          accumulator.to_response
        end

        private

        def build_body(request)
          body = {
            'contents' => request.messages.reject { |m| m.role == :system }.map { |m| serialize_message(m) }
          }

          system_text = request.system || request.messages.select { |m| m.role == :system }.map(&:text).join("\n")
          body['systemInstruction'] = { 'parts' => [{ 'text' => system_text }] } unless system_text.empty?

          config = {}
          config['temperature'] = request.temperature if request.temperature
          config['maxOutputTokens'] = request.max_tokens if request.max_tokens
          config['stopSequences'] = request.stop_sequences if request.stop_sequences
          body['generationConfig'] = config unless config.empty?

          if request.tools&.any?
            body['tools'] = [{ 'functionDeclarations' => request.tools.map { |t| serialize_tool(t) } }]
          end

          body
        end

        def serialize_message(message)
          role = message.role == :assistant ? 'model' : 'user'
          parts = message.content.map { |p| serialize_part(p) }
          { 'role' => role, 'parts' => parts }
        end

        def serialize_part(part)
          case part.type
          when :text then { 'text' => part.text }
          when :image
            if part.url?
              { 'fileData' => { 'fileUri' => part.source, 'mimeType' => part.media_type } }
            else
              { 'inlineData' => { 'data' => part.source, 'mimeType' => part.media_type } }
            end
          when :tool_use
            { 'functionCall' => { 'name' => part.name, 'args' => part.input } }
          when :tool_result
            { 'functionResponse' => { 'name' => part.tool_use_id, 'response' => { 'result' => part.content } } }
          else
            { 'text' => part.to_s }
          end
        end

        def serialize_tool(tool)
          { 'name' => tool.name, 'description' => tool.description, 'parameters' => tool.input_schema }
        end

        def parse_response(raw, model)
          candidates = raw['candidates'] || []
          candidate = candidates.first || {}
          parts = candidate.dig('content', 'parts') || []
          content = parts.map { |p| parse_part(p) }

          usage_meta = raw['usageMetadata'] || {}
          usage = Usage.new(
            input_tokens: usage_meta['promptTokenCount'] || 0,
            output_tokens: usage_meta['candidatesTokenCount'] || 0,
            reasoning_tokens: usage_meta['thoughtsTokenCount'] || 0
          )

          reason_raw = candidate['finishReason'] || 'STOP'
          finish = FinishReason.from_provider(reason_raw)

          Response.new(
            id: nil,
            model: model,
            content: content,
            usage: usage,
            finish_reason: finish,
            raw: raw
          )
        end

        def parse_part(part)
          if part['text']
            ContentPart.text(part['text'])
          elsif part['functionCall']
            fc = part['functionCall']
            ContentPart.tool_use(id: fc['name'], name: fc['name'], input: fc['args'] || {})
          elsif part['thought']
            ContentPart.thinking(text: part['thought'])
          else
            ContentPart.text(part.to_s)
          end
        end

        def translate_stream_chunk(data)
          events = []
          candidates = data['candidates'] || []
          candidate = candidates.first || {}
          parts = candidate.dig('content', 'parts') || []

          parts.each do |part|
            if part['text']
              events << StreamEvent.new(type: :content_delta, data: { text: part['text'] })
            elsif part['functionCall']
              fc = part['functionCall']
              events << StreamEvent.new(type: :tool_call_delta, data: {
                                          id: fc['name'], name: fc['name'], arguments: JSON.generate(fc['args'] || {})
                                        })
            elsif part['thought']
              events << StreamEvent.new(type: :thinking_delta, data: { text: part['thought'] })
            end
          end

          if candidate['finishReason']
            usage_meta = data['usageMetadata'] || {}
            events << StreamEvent.new(type: :message_end, data: {
                                        finish_reason: FinishReason.from_provider(candidate['finishReason']),
                                        input_tokens: usage_meta['promptTokenCount'],
                                        output_tokens: usage_meta['candidatesTokenCount']
                                      })
          end

          events
        end
      end
    end
  end
end
