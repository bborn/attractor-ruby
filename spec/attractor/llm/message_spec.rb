# frozen_string_literal: true

RSpec.describe Attractor::LLM::Message do
  describe '.user' do
    it 'creates a user message from text' do
      msg = described_class.user('Hello')
      expect(msg.role).to eq(:user)
      expect(msg.text).to eq('Hello')
    end
  end

  describe '.assistant' do
    it 'creates an assistant message from text' do
      msg = described_class.assistant('Hi there')
      expect(msg.role).to eq(:assistant)
      expect(msg.text).to eq('Hi there')
    end
  end

  describe '#content' do
    it 'normalizes string to text content part' do
      msg = described_class.new(role: :user, content: 'test')
      expect(msg.content.length).to eq(1)
      expect(msg.content.first.type).to eq(:text)
      expect(msg.content.first.text).to eq('test')
    end

    it 'accepts array of content parts' do
      parts = [
        Attractor::LLM::ContentPart.text('Hello'),
        Attractor::LLM::ContentPart.text('World')
      ]
      msg = described_class.new(role: :user, content: parts)
      expect(msg.text).to eq('HelloWorld')
    end
  end

  describe '#tool_calls' do
    it 'returns tool use parts' do
      parts = [
        Attractor::LLM::ContentPart.text('Let me help'),
        Attractor::LLM::ContentPart.tool_use(id: 'tc_1', name: 'read_file', input: { 'path' => 'foo.rb' })
      ]
      msg = described_class.new(role: :assistant, content: parts)
      expect(msg.tool_calls.length).to eq(1)
      expect(msg.tool_calls.first.name).to eq('read_file')
    end
  end

  describe 'role validation' do
    it 'raises on invalid role' do
      expect { described_class.new(role: :invalid, content: 'x') }.to raise_error(ArgumentError)
    end
  end
end
