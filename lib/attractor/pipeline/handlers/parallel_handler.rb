# frozen_string_literal: true

require 'concurrent'

module Attractor
  module Pipeline
    module Handlers
      class ParallelHandler
        include Base

        def handler_type = :parallel

        def handle(node, context, engine)
          edges = engine.graph.edges_from(node.id)

          return Outcome.error(error_message: "Parallel node '#{node.id}' has no outgoing edges") if edges.empty?

          # Execute each branch concurrently
          futures = edges.map do |edge|
            branch_context = context.clone
            Concurrent::Future.execute do
              engine.execute_branch(edge.to, branch_context)
            end
          end

          # Collect results
          results = futures.map do |future|
            future.value(300) # 5 minute timeout per branch
          end

          updates = {}
          results.each_with_index do |result, i|
            branch_id = edges[i].to
            updates["#{node.id}.branch.#{branch_id}"] = result.to_s
          end

          Outcome.success(
            output: results.map(&:to_s).join("\n---\n"),
            updates: updates
          )
        end
      end
    end
  end
end
