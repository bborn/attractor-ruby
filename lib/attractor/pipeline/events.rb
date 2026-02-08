# frozen_string_literal: true

module Attractor
  module Pipeline
    module PipelineEvents
      KINDS = %i[
        pipeline_start pipeline_end
        node_enter node_exit
        edge_selected
        checkpoint_saved checkpoint_restored
        goal_gate_check goal_gate_fail
        retry_attempt
        parallel_start parallel_end
        error
      ].freeze
    end

    class PipelineEventEmitter
      def initialize
        @listeners = Hash.new { |h, k| h[k] = [] }
      end

      def on(event_kind, &block)
        @listeners[event_kind] << block
        self
      end

      def emit(event_kind, data = {})
        @listeners[event_kind].each { |cb| cb.call(data) }
        @listeners[:all].each { |cb| cb.call(event_kind, data) }
      end

      def on_all(&block)
        @listeners[:all] << block
        self
      end
    end
  end
end
