# frozen_string_literal: true

RSpec.describe Attractor::LLM::ModelCatalog do
  describe '.lookup' do
    it 'returns model info for known models' do
      info = described_class.lookup('gpt-4o')
      expect(info).not_to be_nil
      expect(info.provider).to eq(:openai)
      expect(info.supports_tools).to be true
    end

    it 'returns nil for unknown models' do
      expect(described_class.lookup('unknown-model')).to be_nil
    end
  end

  describe '.provider_for' do
    it 'returns provider for known models' do
      expect(described_class.provider_for('gpt-4o')).to eq(:openai)
      expect(described_class.provider_for('claude-sonnet-4-5-20250514')).to eq(:anthropic)
      expect(described_class.provider_for('gemini-2.5-pro')).to eq(:gemini)
    end

    it 'infers provider from prefix' do
      expect(described_class.provider_for('claude-some-new-model')).to eq(:anthropic)
      expect(described_class.provider_for('gpt-5')).to eq(:openai)
      expect(described_class.provider_for('gemini-3.0-ultra')).to eq(:gemini)
    end

    it 'raises for unknown prefix' do
      expect { described_class.provider_for('llama-3') }.to raise_error(Attractor::LLM::ModelNotFoundError)
    end
  end
end
