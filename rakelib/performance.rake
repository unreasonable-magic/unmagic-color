# frozen_string_literal: true

namespace :color_database do
  desc("Measure memory consumption of color databases")
  task :memory do
    require_relative "../lib/unmagic/color"

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

  desc("Benchmark database loading performance")
  task :benchmark do
    require_relative "../lib/unmagic/color"
    require "benchmark"

    databases = {
      "X11" => File.join(Unmagic::Color::DATA_PATH, "x11.jsonc"),
      "CSS" => File.join(Unmagic::Color::DATA_PATH, "css.jsonc"),
    }

    iterations = 100

    puts "Color Database Loading Performance"
    puts "=" * 50

    databases.each do |name, filepath|
      # Benchmark database loading (create new database each time)
      load_times = []
      iterations.times do
        db = Unmagic::Color::RGB::Named::Database.new(path: filepath, name: name.downcase)
        load_times << Benchmark.realtime { db.send(:data) }
      end

      # Create database for lookup benchmarks
      db = Unmagic::Color::RGB::Named::Database.new(path: filepath, name: name.downcase)
      db.send(:data) # Preload

      # Benchmark lookups
      lookup_times = []
      iterations.times do
        lookup_times << Benchmark.realtime { db["goldenrod"] }
      end

      load_avg = load_times.sum / load_times.size
      load_min = load_times.min
      load_max = load_times.max

      lookup_avg = lookup_times.sum / lookup_times.size
      lookup_min = lookup_times.min
      lookup_max = lookup_times.max

      puts "\n#{name} Database:"
      puts "  Colors: #{db.all.size}"
      puts "  Load time (#{iterations} iterations):"
      puts "    Avg: #{(load_avg * 1000).round(3)} ms"
      puts "    Min: #{(load_min * 1000).round(3)} ms"
      puts "    Max: #{(load_max * 1000).round(3)} ms"
      puts "  Lookup time (#{iterations} iterations):"
      puts "    Avg: #{(lookup_avg * 1_000_000).round(3)} µs"
      puts "    Min: #{(lookup_min * 1_000_000).round(3)} µs"
      puts "    Max: #{(lookup_max * 1_000_000).round(3)} µs"
    end

    puts "\n" + "=" * 50
  end
end
