# frozen_string_literal: true

RSpec.describe Attractor::Pipeline::Context do
  it 'stores and retrieves values' do
    ctx = described_class.new
    ctx.set('key', 'value')
    expect(ctx.get('key')).to eq('value')
  end

  it 'supports bracket access' do
    ctx = described_class.new
    ctx['key'] = 'value'
    expect(ctx['key']).to eq('value')
  end

  it 'accepts initial values' do
    ctx = described_class.new('a' => 1, 'b' => 2)
    expect(ctx['a']).to eq(1)
    expect(ctx['b']).to eq(2)
  end

  it 'converts keys to strings' do
    ctx = described_class.new
    ctx.set(:symbol_key, 'val')
    expect(ctx.get('symbol_key')).to eq('val')
  end

  it 'clones without sharing state' do
    original = described_class.new('x' => 1)
    clone = original.clone
    clone['x'] = 2
    expect(original['x']).to eq(1)
    expect(clone['x']).to eq(2)
  end

  it 'serializes to JSON' do
    ctx = described_class.new('a' => 'b')
    json = ctx.to_json
    restored = described_class.from_json(json)
    expect(restored['a']).to eq('b')
  end
end
