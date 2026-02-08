# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class SpawnAgent
        def tool_name = 'spawn_agent'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Spawn a subagent to handle a subtask. Returns the subagent result.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'task' => { 'type' => 'string', 'description' => 'The task for the subagent to complete' },
                'context' => { 'type' => 'string', 'description' => 'Additional context for the subagent' }
              },
              'required' => ['task']
            }
          )
        end

        def call(args, env:)
          # Subagent spawning is handled by the Session via the subagent manager.
          # This tool returns a placeholder; the session intercepts spawn_agent calls.
          "Subagent task queued: #{args['task']}"
        end
      end
    end
  end
end
