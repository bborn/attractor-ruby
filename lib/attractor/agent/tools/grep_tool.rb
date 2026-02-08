# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class GrepTool
        def tool_name = 'grep'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Search file contents using a pattern. Returns matching lines with file paths and line numbers.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'pattern' => { 'type' => 'string', 'description' => 'Search pattern (regex)' },
                'path' => { 'type' => 'string', 'description' => 'Directory or file to search (default: .)' },
                'glob' => { 'type' => 'string', 'description' => "File glob filter (e.g., '*.rb')" },
                'case_insensitive' => { 'type' => 'boolean', 'description' => 'Case insensitive search' }
              },
              'required' => ['pattern']
            }
          )
        end

        def call(args, env:)
          result = env.grep(
            args['pattern'],
            path: args['path'],
            options: {
              glob: args['glob'],
              case_insensitive: args['case_insensitive']
            }
          )
          Truncation.truncate(result)
        end
      end
    end
  end
end
