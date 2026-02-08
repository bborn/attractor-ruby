# frozen_string_literal: true

module Attractor
  module LLM
    # Server-Sent Events parser for streaming LLM responses
    class SSEParser
      def initialize(&block)
        @callback = block
        @buffer = +''
        @event_type = nil
        @data_lines = []
      end

      def feed(chunk)
        @buffer << chunk
        process_buffer
      end

      private

      def process_buffer
        while (line_end = @buffer.index("\n"))
          line = @buffer.slice!(0..line_end).chomp.chomp("\r")
          process_line(line)
        end
      end

      def process_line(line)
        if line.empty?
          dispatch_event
          return
        end

        case line
        when /^event:\s*(.+)/
          @event_type = ::Regexp.last_match(1).strip
        when /^data:\s*(.*)/
          @data_lines << ::Regexp.last_match(1)
        when /^id:\s*/
          # SSE id field - ignored for LLM streams
        when /^retry:\s*/
          # SSE retry field - ignored
        end
      end

      def dispatch_event
        return if @data_lines.empty?

        data = @data_lines.join("\n")
        @callback&.call(@event_type, data) unless data == '[DONE]'

        @event_type = nil
        @data_lines = []
      end
    end
  end
end
