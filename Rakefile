# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "yard"
  require "yard/doctest/rake"

  YARD::Doctest::RakeTask.new do |task|
    task.doctest_opts = ["-v"]
    task.pattern = "lib/**/*.rb"
  end

  desc("Start YARD documentation server with auto-reload")
  task(:server) do
    sh("bundle exec yard server --reload")
  end
rescue LoadError
  # yard-doctest not available
end

desc("Run all CI checks (rubocop, spec, yard-lint, yard:doctest)")
task ci: ["rubocop", "spec", "yard_lint", "yard:doctest"]

desc("Run RuboCop")
task :rubocop do
  sh("bundle exec rubocop")
end

desc("Run YARD Lint")
task :yard_lint do
  sh("bundle exec yard-lint")
end

task default: :spec
