# frozen_string_literal: true

module Attractor
  module LLM
    module Providers
      class OpenAIAdapter
        include BaseAdapter

        DEFAULT_BASE_URL = 'https://api.openai.com'

        def self.provider_name = :openai

        def initialize(api_key:, base_url: DEFAULT_BASE_URL)
          @api_key = api_key
          @base_url = base_url
        end

        def complete(request)
          body = build_body(request)
          raw = http_post("#{base_url}/v1/responses", headers: auth_headers, body: body)
          parse_response(raw)
        end

        def stream(request, &block)
          body = build_body(request).merge('stream' => true)
          accumulator = StreamAccumulator.new

          sse = SSEParser.new do |_event_type, data|
            parsed = JSON.parse(data, symbolize_names: false)
            event = translate_stream_event(parsed)
            next unless event

            accumulator.accumulate(event)
            block&.call(event)
          end

          http_post("#{base_url}/v1/responses", headers: auth_headers, body: body) do |chunk|
            sse.feed(chunk)
          end

          accumulator.to_response
        end

        private

        def auth_headers
          default_headers.merge('Authorization' => "Bearer #{api_key}")
        end

        def build_body(request)
          body = {
            'model' => request.model,
            'input' => build_input(request)
          }
          body['instructions'] = request.system if request.system
          body['temperature'] = request.temperature if request.temperature
          body['max_output_tokens'] = request.max_tokens if request.max_tokens
          body['tools'] = request.tools.map { |t| serialize_tool(t) } if request.tools&.any?
          body['tool_choice'] = request.tool_choice.to_s if request.tool_choice
          body
        end

        def build_input(request)
          request.messages.map { |m| serialize_message(m) }
        end

        def serialize_message(message)
          msg = { 'role' => message.role.to_s }
          text_parts = message.content.select { |p| p.type == :text }
          tool_parts = message.content.select { |p| p.type == :tool_use }
          tool_result_parts = message.content.select { |p| p.type == :tool_result }

          if tool_result_parts.any?
            msg['role'] = 'tool'
            msg['tool_call_id'] = tool_result_parts.first.tool_use_id
            msg['content'] = tool_result_parts.first.content.to_s
          elsif tool_parts.any?
            msg['content'] = text_parts.map(&:to_s).join
            msg['tool_calls'] = tool_parts.map do |tp|
              { 'id' => tp.id, 'type' => 'function', 'function' => { 'name' => tp.name, 'arguments' => JSON.generate(tp.input) } }
            end
          else
            msg['content'] = text_parts.map(&:to_s).join
          end
          msg
        end

        def serialize_tool(tool)
          {
            'type' => 'function',
            'name' => tool.name,
            'description' => tool.description,
            'parameters' => tool.input_schema
          }
        end

        def parse_response(raw)
          output = raw['output'] || []
          content = output.flat_map { |item| parse_output_item(item) }
          usage = parse_usage(raw['usage'] || {})
          status = raw['status'] || 'completed'
          finish = FinishReason.from_provider(status == 'completed' ? 'stop' : status)

          Response.new(
            id: raw['id'],
            model: raw['model'],
            content: content,
            usage: usage,
            finish_reason: finish,
            raw: raw
          )
        end

        def parse_output_item(item)
          case item['type']
          when 'message'
            (item['content'] || []).map do |c|
              case c['type']
              when 'output_text' then ContentPart.text(c['text'])
              else ContentPart.text(c.to_s)
              end
            end
          when 'function_call'
            args = begin
              JSON.parse(item['arguments'] || '{}')
            rescue JSON::ParserError
              {}
            end
            [ContentPart.tool_use(id: item['call_id'], name: item['name'], input: args)]
          when 'reasoning'
            (item['summary'] || []).map do |s|
              ContentPart.thinking(text: s['text'] || '')
            end
          else
            [ContentPart.text(item.to_s)]
          end
        end

        def parse_usage(usage)
          Usage.new(
            input_tokens: usage['input_tokens'] || 0,
            output_tokens: usage['output_tokens'] || 0,
            reasoning_tokens: usage.dig('output_tokens_details', 'reasoning_tokens') || 0
          )
        end

        def translate_stream_event(data)
          type = data['type']
          case type
          when 'response.created'
            StreamEvent.new(type: :message_start, data: {
                              id: data.dig('response', 'id'),
                              model: data.dig('response', 'model')
                            })
          when 'response.output_text.delta'
            StreamEvent.new(type: :content_delta, data: { text: data['delta'] })
          when 'response.function_call_arguments.delta'
            StreamEvent.new(type: :tool_call_delta, data: {
                              id: data['call_id'], arguments: data['delta']
                            })
          when 'response.completed'
            resp = data['response'] || {}
            usage = parse_usage(resp['usage'] || {})
            StreamEvent.new(type: :message_end, data: {
                              finish_reason: FinishReason.from_provider('stop'),
                              input_tokens: usage.input_tokens,
                              output_tokens: usage.output_tokens
                            })
          when 'error'
            StreamEvent.new(type: :error, data: { message: data.dig('error', 'message') })
          end
        end
      end
    end
  end
end
