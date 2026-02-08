# frozen_string_literal: true

RSpec.describe Attractor::Pipeline::Runner do
  let(:backend) { Attractor::Pipeline::Backends::Simulation.new }
  let(:interviewer) { Attractor::Pipeline::Interviewer::AutoApprove.new }

  it 'runs a complete pipeline from DOT source' do
    source = <<~DOT
      digraph example {
        start [shape=Mdiamond]
        task [label="Generate code" prompt="Write a function"]
        done [shape=Msquare]
        start -> task -> done
      }
    DOT

    runner = described_class.new(backend: backend, interviewer: interviewer)
    result = runner.run(source)
    expect(result[:status]).to eq(:success)
  end

  it 'expands variables in prompts' do
    source = <<~DOT
      digraph G {
        start [shape=Mdiamond]
        task [label="Task" prompt="Implement $goal"]
        done [shape=Msquare]
        start -> task -> done
      }
    DOT

    runner = described_class.new(backend: backend, interviewer: interviewer)
    result = runner.run(source, context: { 'goal' => 'authentication' })
    expect(result[:status]).to eq(:success)
  end

  it 'validates before running' do
    invalid_source = <<~DOT
      digraph G {
        orphan [label="No start or exit"]
      }
    DOT

    runner = described_class.new(backend: backend, interviewer: interviewer)
    expect { runner.run(invalid_source) }.to raise_error(Attractor::Pipeline::ValidationError)
  end

  describe '#validate' do
    it 'returns diagnostics without running' do
      source = <<~DOT
        digraph G {
          start [shape=Mdiamond]
          done [shape=Msquare]
          start -> done
        }
      DOT

      runner = described_class.new(backend: backend)
      diagnostics = runner.validate(source)
      expect(diagnostics.select(&:error?)).to be_empty
    end
  end
end
