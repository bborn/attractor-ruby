# frozen_string_literal: true

module Attractor
  module Agent
    module ProviderProfiles
      class GeminiProfile
        include BaseProfile

        def provider_name = :gemini

        def base_system_prompt
          <<~PROMPT
            You are a coding agent. You help users accomplish software engineering tasks by reading, writing, and editing files, and executing shell commands.

            Guidelines:
            - Read files before modifying them to understand context
            - Use edit_file for targeted changes, write_file for creating new files
            - Run tests after making changes to verify correctness
            - Be precise with file paths
          PROMPT
        end

        def tool_classes
          [
            Tools::ReadFile,
            Tools::WriteFile,
            Tools::EditFile,
            Tools::Shell,
            Tools::GrepTool,
            Tools::GlobTool,
            Tools::SpawnAgent
          ]
        end
      end
    end
  end
end
