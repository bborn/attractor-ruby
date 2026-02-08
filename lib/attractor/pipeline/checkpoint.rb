# frozen_string_literal: true

require 'json'

module Attractor
  module Pipeline
    class Checkpoint
      attr_reader :node_id, :context_snapshot, :completed_nodes, :timestamp

      def initialize(node_id:, context_snapshot:, completed_nodes:, timestamp: Time.now)
        @node_id = node_id
        @context_snapshot = context_snapshot
        @completed_nodes = completed_nodes
        @timestamp = timestamp
      end

      def to_json(*_args)
        JSON.generate({
                        node_id: node_id,
                        context: context_snapshot,
                        completed_nodes: completed_nodes,
                        timestamp: timestamp.iso8601
                      })
      end

      def self.from_json(json_str)
        data = JSON.parse(json_str)
        new(
          node_id: data['node_id'],
          context_snapshot: data['context'],
          completed_nodes: data['completed_nodes'],
          timestamp: Time.parse(data['timestamp'])
        )
      end

      def save(path)
        File.write(path, to_json)
      end

      def self.load(path)
        from_json(File.read(path))
      end
    end
  end
end
