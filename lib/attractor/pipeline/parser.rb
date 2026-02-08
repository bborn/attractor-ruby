# frozen_string_literal: true

module Attractor
  module Pipeline
    class Parser
      def initialize(source)
        @tokens = Lexer.new(source).tokenize
        @pos = 0
        @nodes = {}
        @edges = []
        @graph_attrs = {}
        @default_node_attrs = {}
        @default_edge_attrs = {}
        @name = 'pipeline'
      end

      def parse
        expect_keyword('digraph')
        @name = consume_identifier_or_string || 'pipeline'
        expect(:lbrace)
        parse_stmt_list
        expect(:rbrace)

        Graph.new(
          name: @name,
          nodes: @nodes.values,
          edges: @edges,
          graph_attributes: @graph_attrs
        )
      end

      private

      def parse_stmt_list
        loop do
          skip_semicolons
          break if %i[rbrace eof].include?(peek_type)

          parse_stmt
          skip_semicolons
        end
      end

      def parse_stmt
        if peek_keyword?('graph')
          advance
          attrs = parse_attr_list
          @graph_attrs.merge!(attrs)
        elsif peek_keyword?('node')
          advance
          @default_node_attrs.merge!(parse_attr_list)
        elsif peek_keyword?('edge')
          advance
          @default_edge_attrs.merge!(parse_attr_list)
        elsif peek_keyword?('subgraph')
          parse_subgraph
        elsif %i[identifier string number].include?(peek_type)
          parse_node_or_edge
        else
          advance # skip unknown token
        end
      end

      def parse_subgraph
        advance # skip 'subgraph'
        consume_identifier_or_string # optional name
        return unless peek_type == :lbrace

        expect(:lbrace)
        parse_stmt_list
        expect(:rbrace)
      end

      def parse_node_or_edge
        first_id = consume_identifier_or_string
        return unless first_id

        if peek_type == :arrow
          parse_edge_chain(first_id)
        elsif peek_type == :lbracket
          attrs = parse_attr_list
          ensure_node(first_id, attrs)
        else
          ensure_node(first_id)
        end
      end

      def parse_edge_chain(from_id)
        ensure_node(from_id)

        while peek_type == :arrow
          advance # skip ->
          to_id = consume_identifier_or_string
          break unless to_id

          ensure_node(to_id)
          attrs = peek_type == :lbracket ? parse_attr_list : {}
          merged = @default_edge_attrs.merge(attrs)
          @edges << Edge.new(from: from_id, to: to_id, attributes: merged)

          from_id = to_id
        end
      end

      def parse_attr_list
        attrs = {}
        return attrs unless peek_type == :lbracket

        advance # skip [
        until %i[rbracket eof].include?(peek_type)
          key = consume_identifier_or_string
          break unless key

          if peek_type == :equals
            advance # skip =
            value = consume_value
            attrs[key] = value
          end

          advance if %i[comma semicolon].include?(peek_type)
        end
        expect(:rbracket)
        attrs
      end

      def ensure_node(id, extra_attrs = {})
        if @nodes[id]
          @nodes[id].attributes.merge!(extra_attrs) if extra_attrs.any?
        else
          attrs = @default_node_attrs.merge(extra_attrs)
          @nodes[id] = Node.new(id: id, attributes: attrs)
        end
      end

      def consume_identifier_or_string
        return unless %i[identifier string number keyword].include?(peek_type)

        val = current.value
        advance
        val
      end

      def consume_value
        if %i[string identifier number keyword].include?(peek_type)
          val = current.value
          advance
          val
        else
          advance
          ''
        end
      end

      def expect(type)
        if peek_type != type
          t = current
          raise ParseError, "Expected #{type}, got #{t.type} ('#{t.value}') at line #{t.line}:#{t.column}"
        end
        advance
      end

      def expect_keyword(word)
        unless peek_keyword?(word)
          t = current
          raise ParseError, "Expected '#{word}', got '#{t.value}' at line #{t.line}:#{t.column}"
        end
        advance
      end

      def peek_keyword?(word)
        peek_type == :keyword && current.value.downcase == word
      end

      def peek_type
        current.type
      end

      def current
        @tokens[@pos] || Lexer::Token.new(type: :eof, value: nil, line: 0, column: 0)
      end

      def advance
        @pos += 1
      end

      def skip_semicolons
        advance while peek_type == :semicolon
      end
    end
  end
end
