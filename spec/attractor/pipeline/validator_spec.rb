# frozen_string_literal: true

RSpec.describe Attractor::Pipeline::Validator do
  def build_graph(nodes:, edges:)
    Attractor::Pipeline::Graph.new(
      nodes: nodes.map { |id, attrs| Attractor::Pipeline::Node.new(id: id, attributes: attrs) },
      edges: edges.map { |from, to, attrs| Attractor::Pipeline::Edge.new(from: from, to: to, attributes: attrs || {}) }
    )
  end

  describe '#valid?' do
    it 'passes for a valid graph' do
      graph = build_graph(
        nodes: [['start', { 'shape' => 'Mdiamond' }], ['end', { 'shape' => 'Msquare' }]],
        edges: [['start', 'end', nil]]
      )
      expect(described_class.new(graph).valid?).to be true
    end

    it 'fails when no start node' do
      graph = build_graph(
        nodes: [['end', { 'shape' => 'Msquare' }]],
        edges: []
      )
      diagnostics = described_class.new(graph).validate
      expect(diagnostics.any? { |d| d.rule == :no_start }).to be true
    end

    it 'fails when no exit node' do
      graph = build_graph(
        nodes: [['start', { 'shape' => 'Mdiamond' }]],
        edges: []
      )
      diagnostics = described_class.new(graph).validate
      expect(diagnostics.any? { |d| d.rule == :no_exit }).to be true
    end

    it 'warns about unreachable nodes' do
      graph = build_graph(
        nodes: [
          ['start', { 'shape' => 'Mdiamond' }],
          ['end', { 'shape' => 'Msquare' }],
          ['orphan', {}]
        ],
        edges: [['start', 'end', nil]]
      )
      diagnostics = described_class.new(graph).validate
      expect(diagnostics.any? { |d| d.rule == :unreachable_node && d.node_id == 'orphan' }).to be true
    end

    it 'warns about self-loops' do
      graph = build_graph(
        nodes: [['start', { 'shape' => 'Mdiamond' }], ['a', {}], ['end', { 'shape' => 'Msquare' }]],
        edges: [['start', 'a', nil], ['a', 'a', nil], ['a', 'end', nil]]
      )
      diagnostics = described_class.new(graph).validate
      expect(diagnostics.any? { |d| d.rule == :self_loop }).to be true
    end
  end
end
