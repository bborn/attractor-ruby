# frozen_string_literal: true

module Attractor
  module Pipeline
    class ConditionEvaluator
      def initialize(context:, outcome: nil)
        @context = context
        @outcome = outcome
      end

      def evaluate(expression)
        return true if expression.nil? || expression.empty?

        # Split on && for conjunction
        clauses = expression.split('&&').map(&:strip)
        clauses.all? { |clause| evaluate_clause(clause) }
      end

      private

      def evaluate_clause(clause)
        if clause.include?('!=')
          left, right = clause.split('!=', 2).map(&:strip)
          resolve(left) != resolve(right)
        elsif clause.include?('=')
          left, right = clause.split('=', 2).map(&:strip)
          resolve(left) == resolve(right)
        else
          # Bare value - truthy check
          val = resolve(clause)
          val && val != '' && val != 'false' && val != '0'
        end
      end

      def resolve(token)
        token = token.strip
        # Remove surrounding quotes
        if (token.start_with?('"') && token.end_with?('"')) ||
           (token.start_with?("'") && token.end_with?("'"))
          return token[1..-2]
        end

        # Outcome references
        if token.start_with?('outcome.')
          field = token.sub('outcome.', '')
          return resolve_outcome(field)
        end

        # Context variable
        return @context[token].to_s if @context.key?(token)

        # Literal
        token
      end

      def resolve_outcome(field)
        return nil unless @outcome

        case field
        when 'status' then @outcome.status.to_s
        when 'output' then @outcome.output.to_s
        end
      end
    end
  end
end
