# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class GlobTool
        def tool_name = 'glob'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Find files matching a glob pattern. Returns list of matching file paths.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'pattern' => { 'type' => 'string', 'description' => "Glob pattern (e.g., '**/*.rb')" },
                'path' => { 'type' => 'string', 'description' => 'Base directory to search from' }
              },
              'required' => ['pattern']
            }
          )
        end

        def call(args, env:)
          files = env.glob(args['pattern'], base_path: args['path'])
          files.join("\n")
        end
      end
    end
  end
end
