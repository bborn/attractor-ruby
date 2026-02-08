# frozen_string_literal: true

RSpec.describe Attractor::LLM::Usage do
  describe '#total_tokens' do
    it 'returns sum of input and output tokens' do
      usage = described_class.new(input_tokens: 100, output_tokens: 50)
      expect(usage.total_tokens).to eq(150)
    end
  end

  describe '#+' do
    it 'adds token counts from two usages' do
      a = described_class.new(input_tokens: 10, output_tokens: 20, cache_read_tokens: 5)
      b = described_class.new(input_tokens: 30, output_tokens: 40, cache_read_tokens: 15)
      result = a + b
      expect(result.input_tokens).to eq(40)
      expect(result.output_tokens).to eq(60)
      expect(result.cache_read_tokens).to eq(20)
    end
  end

  describe 'ZERO' do
    it 'has all zero values' do
      zero = described_class::ZERO
      expect(zero.input_tokens).to eq(0)
      expect(zero.output_tokens).to eq(0)
      expect(zero.total_tokens).to eq(0)
    end

    it 'is frozen' do
      expect(described_class::ZERO).to be_frozen
    end
  end

  describe '#to_h' do
    it 'returns a hash with all token counts' do
      usage = described_class.new(input_tokens: 10, output_tokens: 20)
      h = usage.to_h
      expect(h[:input_tokens]).to eq(10)
      expect(h[:output_tokens]).to eq(20)
      expect(h[:total_tokens]).to eq(30)
    end
  end
end
