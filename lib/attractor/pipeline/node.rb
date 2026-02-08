# frozen_string_literal: true

module Attractor
  module Pipeline
    class Node
      attr_reader :id, :attributes

      def initialize(id:, attributes: {})
        @id = id
        @attributes = attributes
      end

      def type
        shape = attributes['shape']
        case shape
        when 'Mdiamond' then :start
        when 'Msquare' then :exit
        when 'diamond' then :conditional
        when 'parallelogram' then :parallel
        when 'trapezium' then :fan_in
        when 'hexagon' then :tool
        when 'doubleoctagon' then :manager_loop
        else
          label = attributes['label'] || id
          if label.downcase.start_with?('wait.human')
            :wait_human
          else
            :codergen
          end
        end
      end

      def label
        attributes['label'] || id
      end

      def model
        attributes['model']
      end

      def prompt
        attributes['prompt']
      end

      def goal_gate
        attributes['goal_gate']
      end

      def retry_limit
        (attributes['retry_limit'] || 3).to_i
      end

      def fidelity
        attributes['fidelity']&.to_sym
      end

      def [](key)
        attributes[key]
      end
    end
  end
end
