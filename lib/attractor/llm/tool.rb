# frozen_string_literal: true

module Attractor
  module LLM
    class Tool
      attr_reader :name, :description, :input_schema, :handler

      def initialize(name:, description:, input_schema:, handler: nil)
        @name = name
        @description = description
        @input_schema = input_schema
        @handler = handler
      end

      def execute(arguments)
        raise "No handler registered for tool #{name}" unless handler

        handler.call(arguments)
      end

      def to_h
        {
          name: name,
          description: description,
          input_schema: input_schema
        }
      end
    end
  end
end
