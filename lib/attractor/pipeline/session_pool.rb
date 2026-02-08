# frozen_string_literal: true

module Attractor
  module Pipeline
    class SessionPool
      def initialize
        @sessions = {}
      end

      def get_or_create(key)
        @sessions[key] ||= yield
      end

      def get(key)
        @sessions[key]
      end

      def release(key)
        @sessions.delete(key)
      end

      def clear
        @sessions.clear
      end

      def size
        @sessions.size
      end
    end
  end
end
