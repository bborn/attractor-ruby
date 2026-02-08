# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class WriteFile
        def tool_name = 'write_file'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Create or overwrite a file with the given content.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'path' => { 'type' => 'string', 'description' => 'File path to write' },
                'content' => { 'type' => 'string', 'description' => 'Content to write' }
              },
              'required' => %w[path content]
            }
          )
        end

        def call(args, env:)
          env.write_file(args['path'], args['content'])
        end
      end
    end
  end
end
