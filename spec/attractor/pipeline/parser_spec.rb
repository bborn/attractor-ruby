# frozen_string_literal: true

RSpec.describe Attractor::Pipeline::Parser do
  def parse(source)
    described_class.new(source).parse
  end

  it 'parses a minimal pipeline' do
    graph = parse('digraph G { start [shape=Mdiamond]; finish [shape=Msquare]; start -> finish; }')
    expect(graph.nodes.length).to eq(2)
    expect(graph.edges.length).to eq(1)
    expect(graph.start_node.id).to eq('start')
  end

  it 'parses node attributes' do
    graph = parse('digraph G { task1 [label="Do stuff" model="gpt-4o" prompt="Write code"]; }')
    node = graph.node('task1')
    expect(node.label).to eq('Do stuff')
    expect(node.model).to eq('gpt-4o')
    expect(node.prompt).to eq('Write code')
  end

  it 'parses edge attributes' do
    graph = parse('digraph G { a -> b [label="success" condition="outcome.status=success"]; }')
    edge = graph.edges.first
    expect(edge.label).to eq('success')
    expect(edge.condition).to eq('outcome.status=success')
  end

  it 'parses chained edges' do
    graph = parse('digraph G { a -> b -> c; }')
    expect(graph.nodes.length).to eq(3)
    expect(graph.edges.length).to eq(2)
    expect(graph.edges[0].from).to eq('a')
    expect(graph.edges[0].to).to eq('b')
    expect(graph.edges[1].from).to eq('b')
    expect(graph.edges[1].to).to eq('c')
  end

  it 'parses a spec-example linear pipeline' do
    source = <<~DOT
      digraph linear_pipeline {
        start [shape=Mdiamond]
        plan [label="Generate implementation plan" prompt="Create a plan for $goal"]
        implement [label="Write code" prompt="Implement the plan"]
        review [label="Review code" prompt="Review the implementation"]
        done [shape=Msquare]

        start -> plan -> implement -> review -> done
      }
    DOT

    graph = parse(source)
    expect(graph.name).to eq('linear_pipeline')
    expect(graph.nodes.length).to eq(5)
    expect(graph.edges.length).to eq(4)
    expect(graph.start_node.id).to eq('start')
    expect(graph.exit_nodes.map(&:id)).to eq(['done'])
  end

  it 'parses a branching pipeline with conditionals' do
    source = <<~DOT
      digraph branching {
        start [shape=Mdiamond]
        check [shape=diamond label="Route"]
        pathA [label="Path A"]
        pathB [label="Path B"]
        done [shape=Msquare]

        start -> check
        check -> pathA [label="success"]
        check -> pathB [label="fail"]
        pathA -> done
        pathB -> done
      }
    DOT

    graph = parse(source)
    expect(graph.node('check').type).to eq(:conditional)
    check_edges = graph.edges_from('check')
    expect(check_edges.length).to eq(2)
    expect(check_edges.map(&:label)).to contain_exactly('success', 'fail')
  end

  it 'parses graph-level attributes' do
    source = 'digraph G { graph [stylesheet="* { model: gpt-4o }"]; a; }'
    graph = parse(source)
    expect(graph.graph_attributes['stylesheet']).to eq('* { model: gpt-4o }')
  end

  it 'raises ParseError for invalid input' do
    expect { parse('not valid dot') }.to raise_error(Attractor::Pipeline::ParseError)
  end
end
