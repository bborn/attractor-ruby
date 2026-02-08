# frozen_string_literal: true

RSpec.describe Attractor::Pipeline::Engine do
  let(:backend) { Attractor::Pipeline::Backends::Simulation.new }
  let(:interviewer) { Attractor::Pipeline::Interviewer::AutoApprove.new }

  def build_engine(source, context: {})
    graph = Attractor::Pipeline::Parser.new(source).parse
    ctx = Attractor::Pipeline::Context.new(context)
    described_class.new(graph: graph, backend: backend, interviewer: interviewer, context: ctx)
  end

  it 'runs a simple start -> exit pipeline' do
    source = <<~DOT
      digraph G {
        s [shape=Mdiamond]
        e [shape=Msquare]
        s -> e
      }
    DOT
    result = build_engine(source).run
    expect(result[:status]).to eq(:success)
  end

  it 'runs a pipeline with codergen node' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        task [label="Write code" prompt="Generate a hello world"]
        done [shape=Msquare]
        start -> task -> done
      }
    DOT
    result = build_engine(source).run
    expect(result[:status]).to eq(:success)
    expect(result[:context]['task.status']).to eq('success')
  end

  it 'emits events during execution' do
    source = <<~DOT
      digraph G {
        s [shape=Mdiamond]
        e [shape=Msquare]
        s -> e
      }
    DOT
    engine = build_engine(source)
    events = []
    engine.events.on_all { |kind, _data| events << kind }
    engine.run
    expect(events).to include(:pipeline_start, :node_enter, :node_exit, :pipeline_end)
  end

  it 'handles wait.human nodes' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        review [label="wait.human: Approve changes?" prompt="Do you approve?"]
        done [shape=Msquare]
        start -> review -> done
      }
    DOT
    result = build_engine(source).run
    expect(result[:status]).to eq(:success)
    expect(result[:context]['review.response']).to eq('approved')
  end

  it 'stores node outputs in context' do
    backend = Attractor::Pipeline::Backends::Simulation.new(
      responses: { 'task' => 'Hello World output' }
    )
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        task [label="Task" prompt="Generate"]
        done [shape=Msquare]
        start -> task -> done
      }
    DOT
    graph = Attractor::Pipeline::Parser.new(source).parse
    engine = described_class.new(graph: graph, backend: backend, interviewer: interviewer)
    result = engine.run
    expect(result[:context]['task.output']).to eq('Hello World output')
  end
end
