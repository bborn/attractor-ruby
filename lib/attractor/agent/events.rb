# frozen_string_literal: true

module Attractor
  module Agent
    module Events
      KINDS = %i[
        session_start session_end
        turn_start turn_end
        tool_call_start tool_call_end
        llm_request_start llm_response
        stream_delta
        steering_injected
        loop_detected
        subagent_spawned subagent_completed
        error
      ].freeze
    end
  end
end
