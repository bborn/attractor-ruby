# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class EditFile
        def tool_name = 'edit_file'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Edit a file by replacing an exact string match with new content.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'path' => { 'type' => 'string', 'description' => 'File path to edit' },
                'old_string' => { 'type' => 'string', 'description' => 'Exact string to find and replace' },
                'new_string' => { 'type' => 'string', 'description' => 'Replacement string' }
              },
              'required' => %w[path old_string new_string]
            }
          )
        end

        def call(args, env:)
          path = args['path']
          old_str = args['old_string']
          new_str = args['new_string']

          content = env.read_file_raw(path)
          count = content.scan(old_str).length

          raise ToolExecutionError, "String not found in #{path}" if count.zero?
          raise ToolExecutionError, "String found #{count} times in #{path}, must be unique" if count > 1

          new_content = content.sub(old_str, new_str)
          env.write_file(path, new_content)
          "File edited: #{path}"
        end
      end
    end
  end
end
