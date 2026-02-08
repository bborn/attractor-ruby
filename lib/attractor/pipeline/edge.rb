# frozen_string_literal: true

module Attractor
  module Pipeline
    class Edge
      attr_reader :from, :to, :attributes

      def initialize(from:, to:, attributes: {})
        @from = from
        @to = to
        @attributes = attributes
      end

      def label
        attributes['label']
      end

      def condition
        attributes['condition']
      end

      def weight
        (attributes['weight'] || 1).to_i
      end

      def [](key)
        attributes[key]
      end
    end
  end
end
