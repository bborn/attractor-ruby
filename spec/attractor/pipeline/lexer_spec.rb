# frozen_string_literal: true

RSpec.describe Attractor::Pipeline::Lexer do
  def tokenize(source)
    described_class.new(source).tokenize
  end

  def token_types(source)
    tokenize(source).map(&:type)
  end

  it 'tokenizes a minimal digraph' do
    types = token_types('digraph G { a -> b; }')
    expect(types).to eq(%i[keyword identifier lbrace identifier arrow identifier semicolon rbrace eof])
  end

  it 'tokenizes quoted strings' do
    tokens = tokenize('a [label="Hello World"]')
    string_tok = tokens.find { |t| t.type == :string }
    expect(string_tok.value).to eq('Hello World')
  end

  it 'tokenizes attributes' do
    types = token_types('a [color=red]')
    expect(types).to include(:lbracket, :identifier, :equals, :identifier, :rbracket)
  end

  it 'handles line comments' do
    tokens = tokenize("a // comment\nb")
    identifiers = tokens.select { |t| t.type == :identifier }.map(&:value)
    expect(identifiers).to eq(%w[a b])
  end

  it 'handles block comments' do
    tokens = tokenize("a /* block\ncomment */ b")
    identifiers = tokens.select { |t| t.type == :identifier }.map(&:value)
    expect(identifiers).to eq(%w[a b])
  end

  it 'tokenizes numbers' do
    tokens = tokenize('[weight=2]')
    number_tok = tokens.find { |t| t.type == :number }
    expect(number_tok.value).to eq('2')
  end

  it 'records line and column numbers' do
    tokens = tokenize("a\nb")
    b_tok = tokens.find { |t| t.value == 'b' }
    expect(b_tok.line).to eq(2)
    expect(b_tok.column).to eq(1)
  end

  it 'handles escaped quotes in strings' do
    tokens = tokenize('"hello \\"world\\""')
    string_tok = tokens.find { |t| t.type == :string }
    expect(string_tok.value).to eq('hello "world"')
  end
end
