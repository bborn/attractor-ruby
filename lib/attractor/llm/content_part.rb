# frozen_string_literal: true

module Attractor
  module LLM
    # Tagged union for multimodal content parts
    module ContentPart
      def self.text(text)
        Text.new(text)
      end

      def self.image(source:, media_type: nil)
        Image.new(source: source, media_type: media_type)
      end

      def self.tool_use(id:, name:, input:)
        ToolUse.new(id: id, name: name, input: input)
      end

      def self.tool_result(tool_use_id:, content:, is_error: false)
        ToolResultPart.new(tool_use_id: tool_use_id, content: content, is_error: is_error)
      end

      def self.thinking(text:, signature: nil)
        Thinking.new(text: text, signature: signature)
      end

      def self.from_h(hash)
        # Handle both string and symbol keys/values (JSON round-trip)
        hash = hash.transform_keys(&:to_sym)
        type = hash[:type].to_sym

        case type
        when :text then Text.new(hash[:text])
        when :image then Image.new(source: hash[:source], media_type: hash[:media_type])
        when :tool_use then ToolUse.new(id: hash[:id], name: hash[:name], input: hash[:input])
        when :tool_result then ToolResultPart.new(tool_use_id: hash[:tool_use_id], content: hash[:content], is_error: hash[:is_error])
        when :thinking then Thinking.new(text: hash[:text], signature: hash[:signature])
        else raise "Unknown content part type: #{hash[:type]}"
        end
      end

      class Text
        attr_reader :text

        def initialize(text)
          @text = text
        end

        def type = :text
        def to_s = text
        def to_h = { type: :text, text: text }
      end

      class Image
        attr_reader :source, :media_type

        def initialize(source:, media_type: nil)
          @source = source
          @media_type = media_type
        end

        def type = :image
        def url? = source.start_with?('http')
        def to_h = { type: :image, source: source, media_type: media_type }
      end

      class ToolUse
        attr_reader :id, :name, :input

        def initialize(id:, name:, input:)
          @id = id
          @name = name
          @input = input
        end

        def type = :tool_use
        def to_h = { type: :tool_use, id: id, name: name, input: input }
      end

      class ToolResultPart
        attr_reader :tool_use_id, :content, :is_error

        def initialize(tool_use_id:, content:, is_error: false)
          @tool_use_id = tool_use_id
          @content = content
          @is_error = is_error
        end

        def type = :tool_result
        def error? = is_error
        def to_h = { type: :tool_result, tool_use_id: tool_use_id, content: content, is_error: is_error }
      end

      class Thinking
        attr_reader :text, :signature

        def initialize(text:, signature: nil)
          @text = text
          @signature = signature
        end

        def type = :thinking
        def to_h = { type: :thinking, text: text, signature: signature }
      end
    end
  end
end
