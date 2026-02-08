# frozen_string_literal: true

require_relative 'lib/attractor/version'

Gem::Specification.new do |spec|
  spec.name = 'attractor'
  spec.version = Attractor::VERSION
  spec.authors = ['bborn']

  spec.summary = 'DOT-based pipeline runner for multi-stage AI workflows'
  spec.description = 'Attractor orchestrates AI workflows as directed graphs using Graphviz DOT syntax. ' \
                     'Includes a unified LLM client, coding agent loop, and pipeline execution engine.'
  spec.homepage = 'https://github.com/bborn/attractor-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/bborn/attractor-ruby'
  spec.metadata['changelog_uri'] = "#{spec.metadata['source_code_uri']}/commits/main"
  spec.metadata['bug_tracker_uri'] = "#{spec.metadata['source_code_uri']}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'bin/*', 'LICENSE']
  spec.bindir = 'bin'
  spec.executables = ['attractor']
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby', '~> 1.3'
end
