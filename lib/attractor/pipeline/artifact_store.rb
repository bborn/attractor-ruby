# frozen_string_literal: true

require 'concurrent'

module Attractor
  module Pipeline
    class ArtifactStore
      def initialize
        @store = Concurrent::Hash.new
      end

      def put(name, value, type: :text)
        @store[name.to_s] = { value: value, type: type, timestamp: Time.now }
      end

      def get(name)
        entry = @store[name.to_s]
        entry&.fetch(:value)
      end

      def type_of(name)
        entry = @store[name.to_s]
        entry&.fetch(:type)
      end

      def key?(name)
        @store.key?(name.to_s)
      end

      def keys
        @store.keys
      end

      def to_h
        @store.transform_values { |v| v[:value] }
      end

      def clear
        @store.clear
      end
    end
  end
end
