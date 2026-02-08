# frozen_string_literal: true

require 'concurrent'
require 'json'

module Attractor
  module Pipeline
    class Context
      def initialize(initial = {})
        @store = Concurrent::Hash.new
        initial.each { |k, v| @store[k.to_s] = v }
      end

      def get(key)
        @store[key.to_s]
      end

      def set(key, value)
        @store[key.to_s] = value
      end

      def [](key) = get(key)

      def []=(key, value)
        set(key, value)
      end

      def merge(hash)
        hash.each { |k, v| set(k, v) }
        self
      end

      def key?(key)
        @store.key?(key.to_s)
      end

      def to_h
        @store.to_h
      end

      def clone
        self.class.new(@store.to_h)
      end

      def to_json(*args)
        @store.to_h.to_json(*args)
      end

      def self.from_json(json_str)
        data = JSON.parse(json_str)
        new(data)
      end
    end
  end
end
