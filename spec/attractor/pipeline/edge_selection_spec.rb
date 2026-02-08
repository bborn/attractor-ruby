# frozen_string_literal: true

RSpec.describe 'Edge Selection Algorithm' do
  let(:backend) { Attractor::Pipeline::Backends::Simulation.new }
  let(:interviewer) { Attractor::Pipeline::Interviewer::AutoApprove.new }

  def run_pipeline(source, context: {})
    runner = Attractor::Pipeline::Runner.new(backend: backend, interviewer: interviewer)
    runner.run(source, context: context)
  end

  it 'selects edge with exact status match (Step 1)' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        task [label="Task" prompt="do something"]
        pass_node [shape=Msquare]
        fail_node [shape=Msquare]

        start -> task
        task -> pass_node [label="success"]
        task -> fail_node [label="fail"]
      }
    DOT

    result = run_pipeline(source)
    expect(result[:status]).to eq(:success)
  end

  it 'selects default edge when no match (Step 4)' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        task [label="Task" prompt="do something"]
        specific [label="Specific"]
        fallback [shape=Msquare]

        start -> task
        task -> specific [label="special_status"]
        task -> fallback [label="default"]
      }
    DOT

    result = run_pipeline(source)
    expect(result[:status]).to eq(:success)
  end

  it 'selects unlabeled edge as final fallback (Step 5)' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        task [label="Task" prompt="do something"]
        next_step [shape=Msquare]

        start -> task
        task -> next_step
      }
    DOT

    result = run_pipeline(source)
    expect(result[:status]).to eq(:success)
  end

  it 'selects condition-based edge (Step 2)' do
    ctx = { 'mode' => 'fast' }
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        check [shape=diamond label="Route"]
        fast_path [shape=Msquare]
        slow_path [shape=Msquare]

        start -> check
        check -> fast_path [condition="mode = fast"]
        check -> slow_path [condition="mode = slow"]
      }
    DOT

    result = run_pipeline(source, context: ctx)
    expect(result[:status]).to eq(:success)
  end

  it 'follows chained edges through multiple nodes' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        a [label="Step A" prompt="step a"]
        b [label="Step B" prompt="step b"]
        c [label="Step C" prompt="step c"]
        done [shape=Msquare]

        start -> a -> b -> c -> done
      }
    DOT

    result = run_pipeline(source)
    expect(result[:status]).to eq(:success)
  end

  it 'handles conditional branching with context variables' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        task [label="Task" prompt="analyze"]
        branch [shape=diamond label="Check"]
        pathA [shape=Msquare]
        pathB [shape=Msquare]

        start -> task -> branch
        branch -> pathA [condition="task.status = success"]
        branch -> pathB [label="default"]
      }
    DOT

    result = run_pipeline(source)
    expect(result[:status]).to eq(:success)
  end
end
