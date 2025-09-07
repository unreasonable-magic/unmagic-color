# frozen_string_literal: true

module Unmagic
  class Color
    # RGB color representation
    class RGB < Unmagic::Color
        # Check if a string is a valid RGB color
        def self.valid?(value)
          return false unless value.is_a?(String)
          
          # Remove rgb() wrapper if present
          clean = value.gsub(/^rgb\s*\(\s*|\s*\)$/, "").strip
          
          # Split and check values
          values = clean.split(/\s*,\s*/)
          return false unless values.length == 3
          
          # Check if all values are valid integers 0-255
          values.all? { |v| v.match?(/\A\d+\z/) && v.to_i.between?(0, 255) }
        rescue
          false
        end
        
        # Parse RGB string like "rgb(255, 128, 0)" or "255, 128, 0"
        def self.parse(input)
          return nil unless input.is_a?(String)
          
          # Remove rgb() wrapper if present
          clean = input.gsub(/^rgb\s*\(\s*|\s*\)$/, "").strip
          
          # Split values
          values = clean.split(/\s*,\s*/)
          return nil unless values.length == 3
          
          # Check if all values are numeric (allow negative for clamping)
          return nil unless values.all? { |v| v.match?(/\A-?\d+\z/) }
          
          # Convert to integers (base class will clamp)
          parsed = values.map(&:to_i)
          
          new(red: parsed[0], green: parsed[1], blue: parsed[2])
        rescue
          nil
        end
    end
  end
end