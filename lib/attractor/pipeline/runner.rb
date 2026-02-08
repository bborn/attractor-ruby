# frozen_string_literal: true

module Attractor
  module Pipeline
    class Runner
      attr_reader :events

      def initialize(backend:, interviewer: nil, execution_env: nil,
                     fidelity_resolver: nil, checkpoint_dir: nil)
        @backend = backend
        @interviewer = interviewer
        @execution_env = execution_env
        @fidelity_resolver = fidelity_resolver || FidelityResolver.new
        @checkpoint_dir = checkpoint_dir
        @events = PipelineEventEmitter.new
      end

      def run(source, context: {}, from_checkpoint: nil)
        # Phase 1: Parse
        graph = Parser.new(source).parse

        # Phase 2: Validate
        diagnostics = Validator.new(graph).validate
        errors = diagnostics.select(&:error?)
        raise ValidationError, "Validation failed:\n#{errors.map(&:to_s).join("\n")}" unless errors.empty?

        # Phase 3: Transform
        ctx = Context.new(context)
        apply_transforms(graph, ctx)

        # Phase 4: Execute
        engine = Engine.new(
          graph: graph,
          backend: @backend,
          interviewer: @interviewer,
          context: ctx,
          execution_env: @execution_env,
          checkpoint_dir: @checkpoint_dir
        )

        # Forward engine events to runner events
        engine.events.on_all do |kind, data|
          @events.emit(kind, data)
        end

        engine.run(from_checkpoint: from_checkpoint)
      end

      def validate(source)
        graph = Parser.new(source).parse
        Validator.new(graph).validate
      end

      def parse(source)
        Parser.new(source).parse
      end

      private

      def apply_transforms(graph, context)
        transforms = [
          Transforms::VariableExpansion.new,
          Transforms::StylesheetApplication.new
        ]
        transforms.each { |t| t.apply(graph, context) }
      end
    end
  end
end
