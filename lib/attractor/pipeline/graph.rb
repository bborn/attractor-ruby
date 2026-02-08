# frozen_string_literal: true

module Attractor
  module Pipeline
    class Graph
      attr_reader :name, :nodes, :edges, :graph_attributes

      def initialize(name: 'pipeline', nodes: [], edges: [], graph_attributes: {})
        @name = name
        @nodes = nodes
        @edges = edges
        @graph_attributes = graph_attributes
        @nodes_by_id = nodes.each_with_object({}) { |n, h| h[n.id] = n }
      end

      def node(id)
        @nodes_by_id[id]
      end

      def edges_from(node_id)
        edges.select { |e| e.from == node_id }
      end

      def edges_to(node_id)
        edges.select { |e| e.to == node_id }
      end

      def start_node
        nodes.find { |n| n.type == :start } || nodes.first
      end

      def exit_nodes
        nodes.select { |n| n.type == :exit }
      end

      def add_node(node)
        @nodes << node
        @nodes_by_id[node.id] = node
      end

      def add_edge(edge)
        @edges << edge
      end

      def node_ids
        nodes.map(&:id)
      end
    end
  end
end
