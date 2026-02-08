# frozen_string_literal: true

RSpec.describe Attractor::LLM::ContentPart do
  describe '.text' do
    it 'creates a text part' do
      part = described_class.text('hello')
      expect(part.type).to eq(:text)
      expect(part.text).to eq('hello')
      expect(part.to_s).to eq('hello')
    end
  end

  describe '.image' do
    it 'creates a URL image' do
      part = described_class.image(source: 'https://example.com/img.png')
      expect(part.type).to eq(:image)
      expect(part.url?).to be true
    end

    it 'creates a base64 image' do
      part = described_class.image(source: 'base64data', media_type: 'image/png')
      expect(part.type).to eq(:image)
      expect(part.url?).to be false
      expect(part.media_type).to eq('image/png')
    end
  end

  describe '.tool_use' do
    it 'creates a tool use part' do
      part = described_class.tool_use(id: 'tc_1', name: 'read', input: { 'path' => 'x' })
      expect(part.type).to eq(:tool_use)
      expect(part.id).to eq('tc_1')
      expect(part.name).to eq('read')
      expect(part.input).to eq({ 'path' => 'x' })
    end
  end

  describe '.tool_result' do
    it 'creates a tool result part' do
      part = described_class.tool_result(tool_use_id: 'tc_1', content: 'done')
      expect(part.type).to eq(:tool_result)
      expect(part.error?).to be false
    end

    it 'creates an error tool result' do
      part = described_class.tool_result(tool_use_id: 'tc_1', content: 'failed', is_error: true)
      expect(part.error?).to be true
    end
  end

  describe '.thinking' do
    it 'creates a thinking part' do
      part = described_class.thinking(text: 'reasoning...', signature: 'sig123')
      expect(part.type).to eq(:thinking)
      expect(part.text).to eq('reasoning...')
      expect(part.signature).to eq('sig123')
    end
  end
end
