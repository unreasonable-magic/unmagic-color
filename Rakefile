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

desc("Measure memory consumption of color databases")
task :memory do
  require_relative "lib/unmagic/color"

  databases = {
    "X11" => Unmagic::Color::RGB::Named::X11,
    "CSS" => Unmagic::Color::RGB::Named::CSS,
  }

  puts "Color Database Memory Usage"
  puts "=" * 50

  databases.each do |name, db|
    color_count = db.all.size
    memory_bytes = db.memsize
    memory_kb = memory_bytes / 1024.0

    puts "\n#{name} Database:"
    puts "  Colors: #{color_count}"
    puts "  Memory: #{memory_kb.round(2)} KB (#{memory_bytes} bytes)"
    puts "  Per color: #{(memory_bytes.to_f / color_count).round(1)} bytes"
  end

  puts "\n" + "=" * 50
end

task default: :spec
