# frozen_string_literal: true

module Attractor
  module Pipeline
    class FidelityResolver
      MODES = %i[full summary none].freeze

      def initialize(default_fidelity: :summary)
        @default_fidelity = default_fidelity
      end

      def resolve(node, graph)
        node_fidelity = node.fidelity
        return node_fidelity if node_fidelity && MODES.include?(node_fidelity)

        graph_fidelity = graph.graph_attributes['fidelity']&.to_sym
        return graph_fidelity if graph_fidelity && MODES.include?(graph_fidelity)

        @default_fidelity
      end

      def build_preamble(mode, context, previous_outputs)
        case mode
        when :full
          nil # Full fidelity - reuse session, no preamble needed
        when :summary
          build_summary_preamble(context, previous_outputs)
        when :none
          nil # No carryover
        end
      end

      private

      def build_summary_preamble(_context, previous_outputs)
        return nil if previous_outputs.empty?

        parts = ['Previous context:']
        previous_outputs.last(3).each do |output|
          parts << "- #{output[:node]}: #{truncate_output(output[:text], 500)}"
        end
        parts.join("\n")
      end

      def truncate_output(text, max)
        return text if text.nil? || text.length <= max

        "#{text[0, max]}..."
      end
    end
  end
end
