# frozen_string_literal: true

module Attractor
  module Agent
    class EventEmitter
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
