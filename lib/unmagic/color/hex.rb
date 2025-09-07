# frozen_string_literal: true

module Unmagic
  class Color
    # Hex color representation
    class Hex < Unmagic::Color
        # Check if a string is a valid hex color
        def self.valid?(value)
          return false unless value.is_a?(String)

          # Clean up the input
          hex = value.strip.gsub(/^#/, "")

          # Check for valid length (3 or 6 characters)
          return false unless hex.length == 3 || hex.length == 6

          # Check if all characters are valid hex digits
          hex.match?(/\A[0-9A-Fa-f]+\z/)
        end

        # Parse hex string like "#FF8800" or "FF8800"
        def self.parse(input)
          return nil unless input.is_a?(String)

          # Clean up the input
          hex = input.strip.gsub(/^#/, "")

          # Handle 3-character hex codes
          if hex.length == 3
            hex = hex.chars.map { |c| c * 2 }.join
          end

          return nil unless hex.length == 6
          return nil unless hex.match?(/\A[0-9A-Fa-f]+\z/)

          r = hex[0..1].to_i(16)
          g = hex[2..3].to_i(16)
          b = hex[4..5].to_i(16)

          new(red: r, green: g, blue: b)
        rescue
          nil
        end
    end
  end
end
