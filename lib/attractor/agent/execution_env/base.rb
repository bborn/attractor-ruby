# frozen_string_literal: true

module Attractor
  module Agent
    module ExecutionEnv
      module Base
        def read_file(path)
          raise NotImplementedError
        end

        def read_file_raw(path)
          raise NotImplementedError
        end

        def write_file(path, content)
          raise NotImplementedError
        end

        def file_exists?(path)
          raise NotImplementedError
        end

        def execute_command(command, timeout: nil)
          raise NotImplementedError
        end

        def glob(pattern, base_path: nil)
          raise NotImplementedError
        end

        def grep(pattern, path: nil, options: {})
          raise NotImplementedError
        end

        def working_directory
          raise NotImplementedError
        end
      end
    end
  end
end
