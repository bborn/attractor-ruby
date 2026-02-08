# frozen_string_literal: true

module Attractor
  module Pipeline
    class Outcome
      STATUSES = %i[success fail skip error].freeze

      attr_reader :status, :updates, :output, :error_message

      def initialize(status:, updates: {}, output: nil, error_message: nil)
        @status = status
        @updates = updates
        @output = output
        @error_message = error_message
      end

      def success? = status == :success
      def fail? = status == :fail
      def skip? = status == :skip
      def error? = status == :error

      def self.success(output: nil, updates: {})
        new(status: :success, output: output, updates: updates)
      end

      def self.fail(output: nil, error_message: nil, updates: {})
        new(status: :fail, output: output, error_message: error_message, updates: updates)
      end

      def self.skip(updates: {})
        new(status: :skip, updates: updates)
      end

      def self.error(error_message:, updates: {})
        new(status: :error, error_message: error_message, updates: updates)
      end
    end
  end
end
