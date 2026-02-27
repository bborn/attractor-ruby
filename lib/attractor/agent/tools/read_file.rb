# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class ReadFile
        def tool_name = 'read_file'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Read the contents of a file. Returns line-numbered content.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'path' => { 'type' => 'string', 'description' => 'File path to read' },
                'offset' => { 'type' => 'integer', 'description' => 'Starting line number (1-based)' },
                'limit' => { 'type' => 'integer', 'description' => 'Number of lines to read' }
              },
              'required' => ['path']
            }
          )
        end

        def call(args, env:, config: nil)
          content = env.read_file(args['path'])
          if args['offset'] || args['limit']
            lines = content.lines
            offset = (args['offset'] || 1) - 1
            limit = args['limit'] || lines.length
            content = lines[offset, limit]&.join || ''
          end
          max_chars = config&.output_truncation_chars || 10_000
          Truncation.truncate(content, max_chars: max_chars)
        end
      end
    end
  end
end
