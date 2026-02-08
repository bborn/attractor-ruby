# frozen_string_literal: true

RSpec.describe Attractor::LLM::FinishReason do
  describe '#stop?' do
    it 'returns true for end_turn' do
      reason = described_class.new(:end_turn)
      expect(reason.stop?).to be true
    end

    it 'returns false for tool_use' do
      reason = described_class.new(:tool_use)
      expect(reason.stop?).to be false
    end
  end

  describe '#tool_use?' do
    it 'returns true for tool_use' do
      reason = described_class.new(:tool_use)
      expect(reason.tool_use?).to be true
    end
  end

  describe '#truncated?' do
    it 'returns true for max_tokens' do
      reason = described_class.new(:max_tokens)
      expect(reason.truncated?).to be true
    end
  end

  describe '.from_provider' do
    it 'maps Anthropic end_turn' do
      reason = described_class.from_provider('end_turn')
      expect(reason.canonical).to eq(:end_turn)
      expect(reason.raw).to eq('end_turn')
    end

    it 'maps OpenAI stop' do
      reason = described_class.from_provider('stop')
      expect(reason.canonical).to eq(:end_turn)
    end

    it 'maps Gemini STOP' do
      reason = described_class.from_provider('STOP')
      expect(reason.canonical).to eq(:end_turn)
    end

    it 'maps tool_calls to tool_use' do
      reason = described_class.from_provider('tool_calls')
      expect(reason.canonical).to eq(:tool_use)
    end

    it 'maps unknown to error' do
      reason = described_class.from_provider('unknown_reason')
      expect(reason.canonical).to eq(:error)
    end
  end

  describe '#==' do
    it 'compares with symbol' do
      reason = described_class.new(:end_turn)
      expect(reason == :end_turn).to be true
      expect(reason == :tool_use).to be false
    end

    it 'compares with string' do
      reason = described_class.new(:end_turn, raw: 'stop')
      expect(reason == 'stop').to be true
    end

    it 'compares with another FinishReason' do
      a = described_class.new(:end_turn)
      b = described_class.new(:end_turn, raw: 'stop')
      expect(a == b).to be true
    end
  end

  describe 'validation' do
    it 'raises on unknown canonical reason' do
      expect { described_class.new(:bogus) }.to raise_error(ArgumentError)
    end
  end
end
