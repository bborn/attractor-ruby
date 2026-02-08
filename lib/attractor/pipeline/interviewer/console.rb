# frozen_string_literal: true

module Attractor
  module Pipeline
    module Interviewer
      class Console
        include Base

        def initialize(input: $stdin, output: $stdout)
          @input = input
          @output = output
        end

        def ask(question, node:, context:)
          @output.puts "\n[#{node.id}] #{question}"
          @output.print '> '
          @output.flush
          @input.gets&.chomp
        end
      end
    end
  end
end
