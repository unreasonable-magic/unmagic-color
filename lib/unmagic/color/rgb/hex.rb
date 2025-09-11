# frozen_string_literal: true

module Unmagic
  class Color
    class RGB
      class Hex
        class ParseError < Color::Error; end

        # Check if a string is a valid hex color
        def self.valid?(value)
          parse(value)
          true
        rescue ParseError
          false
        end

        # Parse hex string like "#FF8800" or "FF8800"
        def self.parse(input)
          raise ParseError.new("Input must be a string") unless input.is_a?(String)

          # Clean up the input
          hex = input.strip.gsub(/^#/, "")

          # Check for valid length (3 or 6 characters)
          unless hex.length == 3 || hex.length == 6
            raise ParseError.new("Invalid number of characters (got #{hex.length}, expected 3 or 6)")
          end

          # Check if all characters are valid hex digits
          unless hex.match?(/\A[0-9A-Fa-f]+\z/)
            invalid_chars = hex.chars.reject { |c| c.match?(/[0-9A-Fa-f]/) }
            raise ParseError.new("Invalid hex characters: #{invalid_chars.join(', ')}")
          end

          # Handle 3-character hex codes
          if hex.length == 3
            hex = hex.chars.map { |c| c * 2 }.join
          end

          r = hex[0..1].to_i(16)
          g = hex[2..3].to_i(16)
          b = hex[4..5].to_i(16)

          RGB.new(red: r, green: g, blue: b)
        end
      end
    end
  end
end
