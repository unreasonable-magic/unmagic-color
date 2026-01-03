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

task default: :spec
