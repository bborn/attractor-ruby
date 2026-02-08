# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class Shell
        def tool_name = 'shell'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Execute a shell command and return stdout, stderr, and exit code.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'command' => { 'type' => 'string', 'description' => 'Shell command to execute' },
                'timeout' => { 'type' => 'integer', 'description' => 'Timeout in seconds (default: 120)' }
              },
              'required' => ['command']
            }
          )
        end

        def call(args, env:)
          result = env.execute_command(args['command'], timeout: args['timeout'] || 120)
          output = +''
          output << result[:stdout] unless result[:stdout].empty?
          output << "\nSTDERR:\n#{result[:stderr]}" unless result[:stderr].empty?
          output << "\nExit code: #{result[:exit_code]}"
          Truncation.truncate(output)
        end
      end
    end
  end
end
