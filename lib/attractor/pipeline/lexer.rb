# frozen_string_literal: true

module Attractor
  module Pipeline
    class Lexer
      Token = Struct.new(:type, :value, :line, :column, keyword_init: true)

      KEYWORDS = %w[digraph graph subgraph node edge strict].freeze

      def initialize(source)
        @source = source
        @pos = 0
        @line = 1
        @column = 1
        @tokens = []
      end

      def tokenize
        @tokens = []
        while @pos < @source.length
          skip_whitespace_and_comments
          break if @pos >= @source.length

          token = read_token
          @tokens << token if token
        end
        @tokens << Token.new(type: :eof, value: nil, line: @line, column: @column)
        @tokens
      end

      private

      def read_token
        ch = @source[@pos]

        case ch
        when '{' then single_char(:lbrace)
        when '}' then single_char(:rbrace)
        when '[' then single_char(:lbracket)
        when ']' then single_char(:rbracket)
        when ';' then single_char(:semicolon)
        when ',' then single_char(:comma)
        when '=' then single_char(:equals)
        when '-'
          if @source[@pos + 1] == '>'
            t = Token.new(type: :arrow, value: '->', line: @line, column: @column)
            advance(2)
            t
          else
            read_identifier
          end
        when '"' then read_quoted_string
        when '<' then read_html_string
        else
          if identifier_start?(ch)
            read_identifier
          elsif /\d/.match?(ch)
            read_number
          else
            advance(1)
            nil
          end
        end
      end

      def single_char(type)
        t = Token.new(type: type, value: @source[@pos], line: @line, column: @column)
        advance(1)
        t
      end

      def read_quoted_string
        start_line = @line
        start_col = @column
        advance(1) # skip opening quote
        str = +''
        while @pos < @source.length && @source[@pos] != '"'
          if @source[@pos] == '\\'
            advance(1)
            str << (@source[@pos] || '')
          else
            str << @source[@pos]
          end
          advance(1)
        end
        advance(1) if @pos < @source.length # skip closing quote
        Token.new(type: :string, value: str, line: start_line, column: start_col)
      end

      def read_html_string
        start_line = @line
        start_col = @column
        depth = 1
        advance(1) # skip <
        str = +''
        while @pos < @source.length && depth.positive?
          ch = @source[@pos]
          if ch == '<'
            depth += 1
          elsif ch == '>'
            depth -= 1
            break if depth.zero?
          end
          str << ch
          advance(1)
        end
        advance(1) # skip >
        Token.new(type: :string, value: str, line: start_line, column: start_col)
      end

      def read_identifier
        start_line = @line
        start_col = @column
        str = +''
        while @pos < @source.length && identifier_char?(@source[@pos])
          str << @source[@pos]
          advance(1)
        end

        type = KEYWORDS.include?(str.downcase) ? :keyword : :identifier
        Token.new(type: type, value: str, line: start_line, column: start_col)
      end

      def read_number
        start_line = @line
        start_col = @column
        str = +''
        while @pos < @source.length && @source[@pos] =~ /[\d.]/
          str << @source[@pos]
          advance(1)
        end
        Token.new(type: :number, value: str, line: start_line, column: start_col)
      end

      def skip_whitespace_and_comments
        loop do
          # Whitespace
          advance(1) while @pos < @source.length && @source[@pos] =~ /\s/

          # Line comments
          if @pos < @source.length && @source[@pos..(@pos + 1)] == '//'
            advance(1) while @pos < @source.length && @source[@pos] != "\n"
            next
          end

          # Block comments
          if @pos < @source.length && @source[@pos..(@pos + 1)] == '/*'
            advance(2)
            while @pos < @source.length - 1
              if @source[@pos..(@pos + 1)] == '*/'
                advance(2)
                break
              end
              advance(1)
            end
            next
          end

          break
        end
      end

      def advance(n = 1)
        n.times do
          if @source[@pos] == "\n"
            @line += 1
            @column = 1
          else
            @column += 1
          end
          @pos += 1
        end
      end

      def identifier_start?(ch)
        ch =~ /[a-zA-Z_]/
      end

      def identifier_char?(ch)
        ch =~ /[a-zA-Z0-9_]/
      end
    end
  end
end
