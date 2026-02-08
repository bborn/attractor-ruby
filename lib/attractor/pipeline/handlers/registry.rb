# frozen_string_literal: true

module Attractor
  module Pipeline
    module Handlers
      class Registry
        def initialize
          @handlers = {}
        end

        def register(type, handler)
          @handlers[type.to_sym] = handler
          self
        end

        def lookup(type)
          @handlers[type.to_sym] || raise(ExecutionError, "No handler for node type: #{type}")
        end

        def self.default
          registry = new
          registry.register(:start, StartHandler.new)
          registry.register(:exit, ExitHandler.new)
          registry.register(:codergen, CodergenHandler.new)
          registry.register(:wait_human, WaitHumanHandler.new)
          registry.register(:conditional, ConditionalHandler.new)
          registry.register(:parallel, ParallelHandler.new)
          registry.register(:fan_in, FanInHandler.new)
          registry.register(:tool, ToolHandler.new)
          registry.register(:manager_loop, ManagerLoopHandler.new)
          registry
        end
      end
    end
  end
end
