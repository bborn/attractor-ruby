# frozen_string_literal: true

RSpec.describe Attractor::Agent::LoopDetector do
  it 'does not detect loop with varied calls' do
    detector = described_class.new(threshold: 3)
    detector.record('read_file', 'hash1')
    detector.record('write_file', 'hash2')
    detector.record('shell', 'hash3')
    expect(detector.loop_detected?).to be false
  end

  it 'detects repeated identical calls' do
    detector = described_class.new(threshold: 3)
    3.times { detector.record('read_file', 'same_hash') }
    expect(detector.loop_detected?).to be true
  end

  it 'resets detection' do
    detector = described_class.new(threshold: 3)
    3.times { detector.record('read_file', 'same_hash') }
    detector.reset
    expect(detector.loop_detected?).to be false
  end

  it 'provides pattern description' do
    detector = described_class.new(threshold: 3)
    3.times { detector.record('read_file', 'hash1') }
    expect(detector.pattern_description).to include('read_file')
  end
end
