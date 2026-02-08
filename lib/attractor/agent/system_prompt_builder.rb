# frozen_string_literal: true

module Attractor
  module Agent
    class SystemPromptBuilder
      def initialize(env:, config:, profile:)
        @env = env
        @config = config
        @profile = profile
      end

      def build(custom_instructions: nil)
        parts = []
        parts << @profile.base_system_prompt
        parts << discover_project_docs
        parts << custom_instructions if custom_instructions
        parts.compact.reject(&:empty?).join("\n\n")
      end

      private

      def discover_project_docs
        docs = []
        @config.project_doc_globs.each do |glob_pattern|
          files = @env.glob(glob_pattern)
          files.each do |file|
            content = File.read(File.join(@env.working_directory, file))
            docs << "# #{file}\n#{content}" unless content.empty?
          rescue Errno::ENOENT
            next
          end
        end
        docs.join("\n\n") unless docs.empty?
      end
    end
  end
end
