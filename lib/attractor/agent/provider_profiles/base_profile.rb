# frozen_string_literal: true

module Attractor
  module Agent
    module ProviderProfiles
      module BaseProfile
        def provider_name
          raise NotImplementedError
        end

        def base_system_prompt
          raise NotImplementedError
        end

        def tool_classes
          raise NotImplementedError
        end

        def build_registry
          registry = Tools::ToolRegistry.new
          tool_classes.each { |tc| registry.register(tc) }
          registry
        end
      end
    end
  end
end
