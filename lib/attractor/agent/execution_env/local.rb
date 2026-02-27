# frozen_string_literal: true

require 'open3'
require 'pathname'

module Attractor
  module Agent
    module ExecutionEnv
      class Local
        include Base

        attr_reader :working_directory

        def initialize(working_directory: Dir.pwd)
          @working_directory = File.expand_path(working_directory)
        end

        def read_file(path)
          full = resolve(path)
          raise ToolExecutionError, "File not found: #{path}" unless File.exist?(full)

          content = File.read(full)
          lines = content.lines
          lines.each_with_index.map { |line, i| "#{i + 1}\t#{line}" }.join
        end

        def read_file_raw(path)
          full = resolve(path)
          raise ToolExecutionError, "File not found: #{path}" unless File.exist?(full)

          File.read(full)
        end

        def write_file(path, content)
          full = resolve(path)
          FileUtils.mkdir_p(File.dirname(full))
          File.write(full, content)
          "File written: #{path} (#{content.bytesize} bytes)"
        end

        def file_exists?(path)
          File.exist?(resolve(path))
        end

        def execute_command(command, timeout: 120)
          stdout, stderr, status = Open3.capture3(
            command,
            chdir: working_directory,
            timeout: timeout
          )
          {
            stdout: stdout,
            stderr: stderr,
            exit_code: status.exitstatus,
            success: status.success?
          }
        rescue Errno::ETIMEDOUT
          { stdout: '', stderr: "Command timed out after #{timeout}s", exit_code: -1, success: false }
        end

        def glob(pattern, base_path: nil)
          base = base_path ? resolve(base_path) : working_directory
          Dir.glob(File.join(base, pattern)).map do |f|
            Pathname.new(f).relative_path_from(Pathname.new(working_directory)).to_s
          end.sort
        end

        def grep(pattern, path: nil, options: {})
          args = ['grep', '-rn']
          args << '-i' if options[:case_insensitive]
          args << "--include=#{options[:glob]}" if options[:glob]
          args << pattern
          args << (path || '.')

          result = execute_command(args.join(' '))
          result[:stdout]
        end

        private

        def resolve(path)
          expanded = File.expand_path(path, working_directory)
          unless expanded.start_with?(working_directory)
            raise ToolExecutionError, "Path escapes working directory: #{path}"
          end

          expanded
        end
      end
    end
  end
end
