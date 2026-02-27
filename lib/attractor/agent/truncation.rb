# frozen_string_literal: true

module Attractor
  module Agent
    module Truncation
      # Head/tail split truncation for tool output
      # Default 10k chars ≈ 2.5k tokens per tool result
      # For cost savings: reduce to 5k (1.25k tokens)
      # For better context: increase to 20k (5k tokens)
      def self.truncate(text, max_chars: 10_000, head_ratio: 0.8)
        return text if text.length <= max_chars

        head_size = (max_chars * head_ratio).to_i
        tail_size = max_chars - head_size
        omitted = text.length - max_chars

        head_part = text[0, head_size]
        tail_part = text[-tail_size, tail_size]

        "#{head_part}\n\n... [#{omitted} characters truncated] ...\n\n#{tail_part}"
      end
    end
  end
end
