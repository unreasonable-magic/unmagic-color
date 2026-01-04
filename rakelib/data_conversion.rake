# frozen_string_literal: true

desc("Convert color data files from .txt to .jsonc format")
task :convert_data do
  require "json"

  ["x11", "css"].each do |db_name|
    txt_file = File.join("data", "#{db_name}.txt")
    jsonc_file = File.join("data", "#{db_name}.jsonc")

    colors = []

    File.readlines(txt_file).each do |line|
      name, hex = line.strip.split("\t")
      next if name.nil? || hex.nil?

      # Normalize name
      normalized = name.downcase.gsub(/\s+/, "")
      next if colors.any? { |c| c[:name] == normalized }

      # Convert hex to integer
      int_value = hex.sub(/^#/, "").to_i(16)
      colors << { name: normalized, int: int_value, hex: hex }
    end

    # Write JSONC file with comments
    File.open(jsonc_file, "w") do |f|
      f.puts "{"
      colors.each_with_index do |color, index|
        comma = index < colors.size - 1 ? "," : ""
        # Align comments at column 40
        padding = " " * [1, 40 - color[:name].length - color[:int].to_s.length - 6].max
        f.puts "  \"#{color[:name]}\": #{color[:int]}#{comma}#{padding}// #{color[:hex]}"
      end
      f.puts "}"
    end

    puts "Converted #{txt_file} -> #{jsonc_file} (#{colors.size} colors)"
  end
end
