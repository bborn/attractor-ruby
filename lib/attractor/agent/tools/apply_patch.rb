# frozen_string_literal: true

module Attractor
  module Agent
    module Tools
      class ApplyPatch
        def tool_name = 'apply_patch'

        def to_llm_tool
          LLM::Tool.new(
            name: tool_name,
            description: 'Apply a v4a unified diff patch to files.',
            input_schema: {
              'type' => 'object',
              'properties' => {
                'patch' => { 'type' => 'string', 'description' => 'The unified diff patch content' }
              },
              'required' => ['patch']
            }
          )
        end

        def call(args, env:)
          patch = args['patch']
          results = []

          parse_hunks(patch).each do |file_path, hunks|
            full_path = File.expand_path(file_path, env.working_directory)

            if hunks.first&.dig(:new_file)
              FileUtils.mkdir_p(File.dirname(full_path))
              content = hunks.first[:additions].join
              File.write(full_path, content)
              results << "Created: #{file_path}"
            elsif File.exist?(full_path)
              content = File.read(full_path)
              lines = content.lines
              hunks.reverse_each do |hunk|
                apply_hunk(lines, hunk)
              end
              File.write(full_path, lines.join)
              results << "Patched: #{file_path}"
            else
              results << "Skipped (not found): #{file_path}"
            end
          end

          results.join("\n")
        end

        private

        def parse_hunks(patch)
          files = {}
          current_file = nil
          current_hunk = nil

          patch.each_line do |line|
            case line
            when %r{^--- a/(.+)}
              current_file = ::Regexp.last_match(1).strip
            when %r{^\+\+\+ b/(.+)}
              current_file = ::Regexp.last_match(1).strip
              files[current_file] ||= []
            when /^@@ -(\d+),?\d* \+(\d+),?\d* @@/
              current_hunk = { old_start: ::Regexp.last_match(1).to_i, new_start: ::Regexp.last_match(2).to_i,
                               removals: [], additions: [] }
              files[current_file] << current_hunk if current_file
            when /^\+(.*)$/
              current_hunk[:additions] << "#{::Regexp.last_match(1)}\n" if current_hunk
            when /^-(.*)$/
              current_hunk[:removals] << "#{::Regexp.last_match(1)}\n" if current_hunk
            end
          end

          files
        end

        def apply_hunk(lines, hunk)
          start = hunk[:old_start] - 1
          remove_count = hunk[:removals].length
          lines[start, remove_count] = hunk[:additions]
        end
      end
    end
  end
end
