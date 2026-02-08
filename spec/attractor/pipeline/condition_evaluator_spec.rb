# frozen_string_literal: true

RSpec.describe Attractor::Pipeline::ConditionEvaluator do
  let(:context) { Attractor::Pipeline::Context.new('status' => 'pass', 'env' => 'production') }

  def evaluate(expression, outcome: nil)
    described_class.new(context: context, outcome: outcome).evaluate(expression)
  end

  it 'returns true for nil expression' do
    expect(evaluate(nil)).to be true
  end

  it 'returns true for empty expression' do
    expect(evaluate('')).to be true
  end

  it 'evaluates equality with context variable' do
    expect(evaluate('status = pass')).to be true
    expect(evaluate('status = fail')).to be false
  end

  it 'evaluates inequality' do
    expect(evaluate('status != fail')).to be true
    expect(evaluate('status != pass')).to be false
  end

  it 'evaluates conjunction (&&)' do
    expect(evaluate('status = pass && env = production')).to be true
    expect(evaluate('status = pass && env = staging')).to be false
  end

  it 'evaluates quoted string literals' do
    expect(evaluate('status = "pass"')).to be true
  end

  it 'evaluates outcome references' do
    outcome = Attractor::Pipeline::Outcome.success(output: 'done')
    expect(evaluate('outcome.status = success', outcome: outcome)).to be true
    expect(evaluate('outcome.status = fail', outcome: outcome)).to be false
  end

  it 'evaluates literal comparison' do
    expect(evaluate('"hello" = "hello"')).to be true
    expect(evaluate('"hello" = "world"')).to be false
  end
end
