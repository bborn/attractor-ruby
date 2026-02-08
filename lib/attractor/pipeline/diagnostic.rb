# frozen_string_literal: true

module Attractor
  module Pipeline
    class Diagnostic
      SEVERITIES = %i[error warning info].freeze

      attr_reader :rule, :severity, :message, :node_id

      def initialize(rule:, severity:, message:, node_id: nil)
        @rule = rule
        @severity = severity
        @message = message
        @node_id = node_id
      end

      def error? = severity == :error
      def warning? = severity == :warning
      def info? = severity == :info

      def to_s
        prefix = node_id ? "[#{node_id}] " : ''
        "#{severity.upcase} #{rule}: #{prefix}#{message}"
      end
    end
  end
end
