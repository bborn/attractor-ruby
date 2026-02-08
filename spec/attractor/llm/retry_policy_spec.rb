# frozen_string_literal: true

RSpec.describe Attractor::LLM::RetryPolicy do
  describe '#should_retry?' do
    it 'returns true for retryable errors within max_retries' do
      policy = described_class.new(max_retries: 3)
      error = Attractor::LLM::RateLimitError.new('rate limited')
      expect(policy.should_retry?(error, 0)).to be true
      expect(policy.should_retry?(error, 2)).to be true
    end

    it 'returns false when attempt equals max_retries' do
      policy = described_class.new(max_retries: 3)
      error = Attractor::LLM::RateLimitError.new('rate limited')
      expect(policy.should_retry?(error, 3)).to be false
    end

    it 'returns false for non-retryable errors' do
      policy = described_class.new(max_retries: 3)
      error = Attractor::LLM::AuthenticationError.new('bad key')
      expect(policy.should_retry?(error, 0)).to be false
    end
  end

  describe '#delay_for' do
    it 'increases exponentially' do
      policy = described_class.new(base_delay: 1.0, jitter: false)
      expect(policy.delay_for(0)).to eq(1.0)
      expect(policy.delay_for(1)).to eq(2.0)
      expect(policy.delay_for(2)).to eq(4.0)
    end

    it 'caps at max_delay' do
      policy = described_class.new(base_delay: 1.0, max_delay: 5.0, jitter: false)
      expect(policy.delay_for(10)).to eq(5.0)
    end
  end

  describe 'NONE' do
    it 'never retries' do
      error = Attractor::LLM::RateLimitError.new('limited')
      expect(described_class::NONE.should_retry?(error, 0)).to be false
    end
  end
end
