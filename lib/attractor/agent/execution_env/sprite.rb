# frozen_string_literal: true

module Attractor
  module Agent
    module ExecutionEnv
      class Sprite
        include Base

        attr_reader :working_directory

        # @param working_directory [String] path on the sprite (default: "/app")
        # @param api [SpritesApi] sprites API client
        # @param sprite_name [String] sprite identifier (e.g. "aghq-chat-42")
        def initialize(working_directory: "/app", api:, sprite_name:)
          @working_directory = working_directory
          @api = api
          @sprite_name = sprite_name
        end

        def read_file(path)
          full = resolve(path)
          result = exec_on_sprite("cat #{shell_escape(full)}")
          raise ToolExecutionError, "File not found: #{path}" unless result[:success]

          content = result[:stdout]
          lines = content.lines
          lines.each_with_index.map { |line, i| "#{i + 1}\t#{line}" }.join
        end

        def read_file_raw(path)
          full = resolve(path)
          result = exec_on_sprite("cat #{shell_escape(full)}")
          raise ToolExecutionError, "File not found: #{path}" unless result[:success]

          result[:stdout]
        end

        def write_file(path, content)
          full = resolve(path)
          @api.fs_write(@sprite_name, path: full, data: content, mkdir: true)
          "File written: #{path} (#{content.bytesize} bytes)"
        rescue SpritesApi::SpriteError => e
          raise ToolExecutionError, "Failed to write #{path} on sprite: #{e.message}"
        end

        def file_exists?(path)
          full = resolve(path)
          result = exec_on_sprite("test -f #{shell_escape(full)} && echo yes || echo no")
          result[:success] && result[:stdout].strip == "yes"
        end

        def execute_command(command, timeout: 120)
          result = exec_on_sprite("cd #{shell_escape(@working_directory)} && #{command}", timeout: timeout)
          {
            stdout: result[:stdout],
            stderr: result[:stderr],
            exit_code: result[:exit_code],
            success: result[:success]
          }
        end

        def glob(pattern, base_path: nil)
          base = base_path ? resolve(base_path) : @working_directory
          # Use find with -path to simulate glob on the sprite
          find_pattern = File.join(base, pattern)
          cmd = "find #{shell_escape(base)} -path #{shell_escape(find_pattern)} -not -path '*/\\.git/*' 2>/dev/null | sort"
          result = exec_on_sprite(cmd)
          return [] unless result[:success]

          result[:stdout].lines.map do |line|
            path = line.strip
            next if path.empty?
            # Return paths relative to working_directory
            if path.start_with?(@working_directory)
              path.sub("#{@working_directory}/", "")
            else
              path
            end
          end.compact
        end

        def grep(pattern, path: nil, options: {})
          args = ["grep", "-rn"]
          args << "-i" if options[:case_insensitive]
          args << "--include=#{options[:glob]}" if options[:glob]
          args << shell_escape(pattern)
          args << (path || ".")

          result = execute_command(args.join(" "))
          result[:stdout]
        end

        private

        def resolve(path)
          full = if path.start_with?("/")
            path
          else
            File.join(@working_directory, path)
          end

          # Collapse ".." and "." segments
          full = File.expand_path(full)

          unless full.start_with?(@working_directory)
            raise ToolExecutionError, "Path escapes working directory: #{path}"
          end

          full
        end

        def exec_on_sprite(command, timeout: 30)
          @api.exec(@sprite_name, ["sh", "-c", command], timeout: timeout)
        rescue SpritesApi::SpriteError => e
          raise ToolExecutionError, "Sprite unreachable: #{e.message}"
        rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET => e
          raise ToolExecutionError, "Sprite connection failed: #{e.message}"
        end

        def shell_escape(str)
          "'" + str.gsub("'", "'\\''") + "'"
        end
      end
    end
  end
end
