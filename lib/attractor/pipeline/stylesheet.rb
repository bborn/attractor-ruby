# frozen_string_literal: true

module Attractor
  module Pipeline
    class Stylesheet
      Rule = Struct.new(:selector, :properties, :specificity, keyword_init: true)

      def initialize(rules = [])
        @rules = rules
      end

      def self.parse(source)
        return new if source.nil? || source.empty?

        rules = []
        source.scan(/([^{]+)\{([^}]*)\}/m) do |selector_str, body|
          selector = selector_str.strip
          properties = parse_properties(body)
          specificity = compute_specificity(selector)
          rules << Rule.new(selector: selector, properties: properties, specificity: specificity)
        end
        new(rules)
      end

      def resolve(node)
        matching = @rules.select { |r| matches?(r.selector, node) }
        merged = {}
        matching.sort_by(&:specificity).each do |rule|
          merged.merge!(rule.properties)
        end
        merged
      end

      private

      def self.parse_properties(body)
        props = {}
        body.strip.split(';').each do |decl|
          next if decl.strip.empty?

          key, value = decl.split(':', 2)
          next unless key && value

          props[key.strip] = value.strip
        end
        props
      end

      def matches?(selector, node)
        parts = selector.split(',').map(&:strip)
        parts.any? { |part| match_single(part, node) }
      end

      def match_single(selector, node)
        case selector
        when '*' then true
        when /^#(.+)/ then node.id == ::Regexp.last_match(1)
        when /^\.(.+)/ then node.type.to_s == ::Regexp.last_match(1)
        when /^\[(.+)=(.+)\]$/
          key = ::Regexp.last_match(1).strip
          val = ::Regexp.last_match(2).strip.gsub(/^["']|["']$/, '')
          node[key] == val
        else
          node.type.to_s == selector || node.id == selector
        end
      end

      def self.compute_specificity(selector)
        parts = selector.split(',')
        parts.map do |s|
          s = s.strip
          case s
          when /^#/ then 100
          when /^\[/ then 50
          when /^\./ then 30
          when '*' then 0
          else 10
          end
        end.max || 0
      end
    end
  end
end
