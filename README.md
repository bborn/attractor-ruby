# Attractor

DOT-based pipeline runner for multi-stage AI workflows.

Attractor orchestrates AI workflows as directed graphs using [Graphviz DOT](https://graphviz.org/doc/info/lang.html) syntax. Define your pipeline as a `.dot` file, and Attractor handles parsing, validation, and execution — routing between nodes based on outcomes, conditions, and edge labels.

## Architecture

Attractor is organized in three layers:

**Layer 1: LLM Client** — A unified interface for calling Anthropic, OpenAI, and Gemini. Supports streaming, tool use, retries, and middleware.

```ruby
client = Attractor::LLM::Client.new(providers: {
  anthropic: { api_key: ENV['ANTHROPIC_API_KEY'] },
  openai: { api_key: ENV['OPENAI_API_KEY'] }
})

request = Attractor::LLM::Request.new(
  model: 'claude-sonnet-4-5-20250514',
  messages: [Attractor::LLM::Message.user('Hello')],
  max_tokens: 1024
)

response = client.complete(request)
```

**Layer 2: Agent Loop** — A coding agent that executes tool calls in a loop (read/write/edit files, shell commands, grep, glob, patches) with loop detection, steering injection, and provider-specific profiles.

```ruby
session = Attractor::Agent::Session.new(
  client: client,
  config: Attractor::Agent::SessionConfig.new(
    model: 'claude-sonnet-4-5-20250514',
    max_turns: 20
  )
)

result = session.process_input('Create a hello world script')
```

**Layer 3: Pipeline Runner** — Parses DOT digraphs into executable pipelines with conditional branching, parallel execution, fan-in, human-in-the-loop gates, retries, checkpointing, and goal gates.

```ruby
pipeline = <<~DOT
  digraph deploy {
    start [shape=Mdiamond]
    review [label="Code Review", model="claude-sonnet-4-5-20250514"]
    fix [label="Fix Issues"]
    approve [shape=diamond]
    done [shape=Msquare]

    start -> review
    review -> approve
    approve -> done [label="success"]
    approve -> fix [label="fail"]
    fix -> review
  }
DOT

runner = Attractor::Pipeline::Runner.new(
  backend: Attractor::Pipeline::Backends::AgentBackend.new(client: client)
)

result = runner.run(pipeline)
```

## Node Types

Node types are determined by the `shape` attribute in DOT:

| Shape | Type | Description |
|---|---|---|
| `Mdiamond` | Start | Entry point |
| `Msquare` | Exit | Terminal node |
| `diamond` | Conditional | Branch based on conditions |
| `parallelogram` | Parallel | Fan-out to concurrent branches |
| `trapezium` | Fan-in | Join parallel branches |
| `hexagon` | Tool | Execute a tool |
| `doubleoctagon` | Manager loop | Iterative manager pattern |
| *(default)* | Codergen | LLM generation node |

## Edge Selection

Edges are selected using a 5-step algorithm:

1. Exact status match (e.g., `[label="success"]`)
2. Condition evaluation (e.g., `[condition="ctx.score > 0.8"]`)
3. Labeled edge matching outcome
4. Default/fallback edge (`[label="default"]`)
5. Unlabeled edge with highest weight

## Backends

- **`Backends::AgentBackend`** — Full agent loop with tools and multi-turn execution
- **`Backends::DirectLLM`** — Single LLM call per node
- **`Backends::Simulation`** — Canned responses for testing

## Installation

Add to your Gemfile:

```ruby
gem 'attractor'
```

## Development

```sh
bundle install
rake          # runs specs and rubocop
rake spec     # specs only
rake rubocop  # lint only
```

## License

MIT
