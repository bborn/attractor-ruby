# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class ToolRegistry
        def initialize
          @tools = {}
        end

        def register(tool_class)
          tool = tool_class.is_a?(Class) ? tool_class.new : tool_class
          @tools[tool.tool_name] = tool
          self
        end

        def lookup(name)
          @tools[name]
        end

        def execute(name, arguments, env:, config: nil)
          tool = @tools[name] || raise(ToolExecutionError, "Unknown tool: #{name}")
          if tool.method(:call).parameters.any? { |type, pname| pname == :config }
            tool.call(arguments, env: env, config: config)
          else
            tool.call(arguments, env: env)
          end
        end

        def to_llm_tools
          @tools.values.map(&:to_llm_tool)
        end

        def tool_names
          @tools.keys
        end
      end
    end
  end
end
