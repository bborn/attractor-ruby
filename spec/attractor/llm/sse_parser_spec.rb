# frozen_string_literal: true

RSpec.describe Attractor::LLM::SSEParser do
  it 'parses a simple SSE stream' do
    events = []
    parser = described_class.new { |type, data| events << [type, data] }

    parser.feed("event: message_start\ndata: {\"id\": \"msg_1\"}\n\n")

    expect(events.length).to eq(1)
    expect(events[0][0]).to eq('message_start')
    expect(events[0][1]).to eq('{"id": "msg_1"}')
  end

  it 'handles multi-line data' do
    events = []
    parser = described_class.new { |type, data| events << [type, data] }

    parser.feed("data: line1\ndata: line2\n\n")

    expect(events.length).to eq(1)
    expect(events[0][1]).to eq("line1\nline2")
  end

  it 'ignores [DONE] sentinel' do
    events = []
    parser = described_class.new { |type, data| events << [type, data] }

    parser.feed("data: [DONE]\n\n")

    expect(events).to be_empty
  end

  it 'handles chunked delivery' do
    events = []
    parser = described_class.new { |type, data| events << [type, data] }

    parser.feed('event: con')
    parser.feed("tent\ndata: {\"text")
    parser.feed("\": \"hello\"}\n\n")

    expect(events.length).to eq(1)
    expect(events[0][0]).to eq('content')
  end

  it 'handles multiple events in one chunk' do
    events = []
    parser = described_class.new { |type, data| events << [type, data] }

    parser.feed("data: first\n\ndata: second\n\n")

    expect(events.length).to eq(2)
  end
end
