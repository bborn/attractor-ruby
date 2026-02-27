# frozen_string_literal: true

module Attractor
  module LLM
    module Providers
      class AnthropicAdapter
        include BaseAdapter

        API_VERSION = '2023-06-01'
        DEFAULT_BASE_URL = 'https://api.anthropic.com'

        def self.provider_name = :anthropic

        def initialize(api_key:, base_url: DEFAULT_BASE_URL)
          @api_key = api_key
          @base_url = base_url
        end

        def complete(request)
          body = build_body(request)
          raw = http_post("#{base_url}/v1/messages", headers: auth_headers, body: body)
          parse_response(raw)
        end

        def stream(request, &block)
          body = build_body(request).merge('stream' => true)
          accumulator = StreamAccumulator.new

          sse = SSEParser.new do |event_type, data|
            parsed = JSON.parse(data, symbolize_names: false)
            event = translate_stream_event(event_type, parsed)
            next unless event

            accumulator.accumulate(event)
            block&.call(event)
          end

          http_post("#{base_url}/v1/messages", headers: auth_headers, body: body) do |chunk|
            sse.feed(chunk)
          end

          accumulator.to_response
        end

        private

        def auth_headers
          default_headers.merge(
            'x-api-key' => api_key,
            'anthropic-version' => API_VERSION
          )
        end

        def build_body(request)
          messages = request.messages.reject { |m| m.role == :system }.map { |m| serialize_message(m) }

          # Mark recent conversation for caching (last few turns before current request)
          # This caches accumulated tool results and conversation history
          if messages.length >= 4
            # Find the second-to-last user message and mark it for caching
            # This ensures we cache all previous turns while keeping current turn fresh
            user_message_indices = messages.each_with_index.select { |m, _| m['role'] == 'user' }.map { |_, i| i }
            if user_message_indices.length >= 2
              cache_index = user_message_indices[-2]  # Second-to-last user message
              last_content = messages[cache_index]['content']
              if last_content.is_a?(Array) && !last_content.empty?
                last_content[-1]['cache_control'] = { 'type' => 'ephemeral' }
              end
            end
          end

          body = {
            'model' => request.model,
            'messages' => messages,
            'max_tokens' => request.max_tokens || 4096
          }

          # Enable prompt caching for system prompt
          if request.system
            body['system'] = [
              {
                'type' => 'text',
                'text' => request.system,
                'cache_control' => { 'type' => 'ephemeral' }
              }
            ]
          end

          body['temperature'] = request.temperature if request.temperature
          body['stop_sequences'] = request.stop_sequences if request.stop_sequences

          # Enable prompt caching for tools
          if request.tools&.any?
            tools = request.tools.map { |t| serialize_tool(t) }
            # Mark the last few tools for caching (cache the whole tool block)
            if tools.length > 3
              tools[-1]['cache_control'] = { 'type' => 'ephemeral' }
            end
            body['tools'] = tools
          end

          body['tool_choice'] = serialize_tool_choice(request.tool_choice) if request.tool_choice
          body
        end

        def serialize_message(message)
          {
            'role' => message.role.to_s,
            'content' => message.content.map { |p| serialize_content_part(p) }
          }
        end

        def serialize_content_part(part)
          case part.type
          when :text
            { 'type' => 'text', 'text' => part.text }
          when :image
            if part.url?
              { 'type' => 'image', 'source' => { 'type' => 'url', 'url' => part.source } }
            else
              { 'type' => 'image',
                'source' => { 'type' => 'base64', 'media_type' => part.media_type, 'data' => part.source } }
            end
          when :tool_use
            { 'type' => 'tool_use', 'id' => part.id, 'name' => part.name, 'input' => part.input }
          when :tool_result
            { 'type' => 'tool_result', 'tool_use_id' => part.tool_use_id, 'content' => part.content.to_s,
              'is_error' => part.is_error }
          when :thinking
            { 'type' => 'thinking', 'thinking' => part.text, 'signature' => part.signature }
          else
            { 'type' => 'text', 'text' => part.to_s }
          end
        end

        def serialize_tool(tool)
          { 'name' => tool.name, 'description' => tool.description, 'input_schema' => tool.input_schema }
        end

        def serialize_tool_choice(choice)
          case choice
          when :auto then { 'type' => 'auto' }
          when :any then { 'type' => 'any' }
          when :none then { 'type' => 'none' }
          when String then { 'type' => 'tool', 'name' => choice }
          else choice
          end
        end

        def parse_response(raw)
          content = (raw['content'] || []).map { |block| parse_content_block(block) }
          usage = parse_usage(raw['usage'] || {})
          finish = FinishReason.from_provider(raw['stop_reason'] || 'end_turn')

          Response.new(
            id: raw['id'],
            model: raw['model'],
            content: content,
            usage: usage,
            finish_reason: finish,
            raw: raw
          )
        end

        def parse_content_block(block)
          case block['type']
          when 'text'
            ContentPart.text(block['text'])
          when 'tool_use'
            ContentPart.tool_use(id: block['id'], name: block['name'], input: block['input'])
          when 'thinking'
            ContentPart.thinking(text: block['thinking'], signature: block['signature'])
          else
            ContentPart.text(block.to_s)
          end
        end

        def parse_usage(usage)
          Usage.new(
            input_tokens: usage['input_tokens'] || 0,
            output_tokens: usage['output_tokens'] || 0,
            cache_read_tokens: usage['cache_read_input_tokens'] || 0,
            cache_write_tokens: usage['cache_creation_input_tokens'] || 0
          )
        end

        def translate_stream_event(event_type, data)
          case event_type
          when 'message_start'
            msg = data['message'] || {}
            StreamEvent.new(type: :message_start, data: {
                              id: msg['id'], model: msg['model']
                            })
          when 'content_block_delta'
            delta = data['delta'] || {}
            case delta['type']
            when 'text_delta'
              StreamEvent.new(type: :content_delta, data: { text: delta['text'] })
            when 'input_json_delta'
              StreamEvent.new(type: :tool_call_delta, data: {
                                index: data['index'], arguments: delta['partial_json']
                              })
            when 'thinking_delta'
              StreamEvent.new(type: :thinking_delta, data: { text: delta['thinking'] })
            end
          when 'content_block_start'
            block = data['content_block'] || {}
            if block['type'] == 'tool_use'
              StreamEvent.new(type: :tool_call_delta, data: {
                                index: data['index'], id: block['id'], name: block['name']
                              })
            end
          when 'message_delta'
            delta = data['delta'] || {}
            usage = data['usage'] || {}
            StreamEvent.new(type: :message_end, data: {
                              finish_reason: FinishReason.from_provider(delta['stop_reason'] || 'end_turn'),
                              output_tokens: usage['output_tokens']
                            })
          when 'error'
            StreamEvent.new(type: :error, data: { message: data.dig('error', 'message') })
          end
        end
      end
    end
  end
end
