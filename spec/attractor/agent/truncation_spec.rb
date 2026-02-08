# frozen_string_literal: true

RSpec.describe Attractor::Agent::Truncation do
  describe '.truncate' do
    it 'returns short text unchanged' do
      text = 'Hello world'
      expect(described_class.truncate(text)).to eq(text)
    end

    it 'truncates long text with head/tail split' do
      text = 'x' * 50_000
      result = described_class.truncate(text, max_chars: 1000)
      expect(result.length).to be < text.length
      expect(result).to include('truncated')
    end

    it 'preserves head and tail of content' do
      text = "HEAD#{'x' * 50_000}TAIL"
      result = described_class.truncate(text, max_chars: 1000)
      expect(result).to start_with('HEAD')
      expect(result).to end_with('TAIL')
    end
  end
end
