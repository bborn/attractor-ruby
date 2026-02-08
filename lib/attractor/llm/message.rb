# frozen_string_literal: true

module Attractor
  module LLM
    class Message
      ROLES = %i[user assistant system].freeze

      attr_reader :role, :content

      def initialize(role:, content:)
        raise ArgumentError, "Invalid role: #{role}" unless ROLES.include?(role)

        @role = role
        @content = normalize_content(content)
      end

      def text
        content.select { |p| p.type == :text }.map(&:to_s).join
      end

      def tool_calls
        content.select { |p| p.type == :tool_use }
      end

      def has_tool_calls?
        content.any? { |p| p.type == :tool_use }
      end

      def thinking_parts
        content.select { |p| p.type == :thinking }
      end

      def self.user(text)
        new(role: :user, content: text)
      end

      def self.assistant(text)
        new(role: :assistant, content: text)
      end

      def self.system(text)
        new(role: :system, content: text)
      end

      private

      def normalize_content(content)
        case content
        when String
          [ContentPart.text(content)]
        when Array
          content
        else
          [content]
        end
      end
    end
  end
end
