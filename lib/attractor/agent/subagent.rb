# frozen_string_literal: true

module Attractor
  module Agent
    class Subagent
      attr_reader :id, :task, :session, :status, :result

      def initialize(id:, task:, session:)
        @id = id
        @task = task
        @session = session
        @status = :pending
        @result = nil
      end

      def run
        @status = :running
        @result = @session.process_input(task)
        @status = :completed
        @result
      rescue StandardError => e
        @status = :failed
        @result = "Error: #{e.message}"
        raise
      end

      def completed? = status == :completed
      def failed? = status == :failed
      def running? = status == :running
    end

    class SubagentManager
      def initialize
        @agents = {}
        @next_id = 0
      end

      def spawn(task:, session:)
        id = "subagent_#{@next_id += 1}"
        agent = Subagent.new(id: id, task: task, session: session)
        @agents[id] = agent
        agent.run
        agent
      end

      def get(id)
        @agents[id]
      end

      def all
        @agents.values
      end

      def close(id)
        @agents.delete(id)
      end

      def close_all
        @agents.clear
      end
    end
  end
end
