# frozen_string_literal: true

module Unmagic
  class Color
    class RGB
      # Hexadecimal color parsing utilities.
      #
      # Hex colors are a compact way to write {RGB} values using hexadecimal (base-16)
      # notation. Each pair of hex digits represents one color component (`0-255`).
      #
      # ## Understanding Hexadecimal
      #
      # Hexadecimal uses 16 digits: `0-9` and `A-F`
      #
      # - `0 = 0`, `9 = 9`, `A = 10`, `B = 11`, ... `F = 15`
      # - Two hex digits can represent `0-255` (`16 × 16 = 256` values)
      # - `FF = 255`, `00 = 0`, `80 = 128`, etc.
      #
      # ## Hex Color Format
      #
      # - **Full format**: `#RRGGBB` (6 digits, 2 per component)
      # - **Short format**: `#RGB` (3 digits, each digit is doubled)
      # - **Hash optional**: Can be written with or without the `#` prefix
      #
      # ## Examples
      #
      # - `#FF0000` = Red (`255, 0, 0`)
      # - `#00FF00` = Green (`0, 255, 0`)
      # - `#0000FF` = Blue (`0, 0, 255`)
      # - `#F00` = `#FF0000` (short form)
      # - `#ABC` = `#AABBCC` (short form expanded)
      class Hex
        # Error raised when parsing hex color strings fails
        class ParseError < Color::Error; end

        class << self
          # Check if a string is a valid hex color.
          #
          # @param value [String] The string to validate
          # @return [Boolean] true if valid hex color, false otherwise
          #
          # @example
          #   Unmagic::Color::RGB::Hex.valid?("#FF5733")
          #   # => true
          #
          #   Unmagic::Color::RGB::Hex.valid?("F73")
          #   # => true
          #
          #   Unmagic::Color::RGB::Hex.valid?("GGGGGG")
          #   # => false
          def valid?(value)
            parse(value)
            true
          rescue ParseError
            false
          end

          # Parse a hexadecimal color string.
          #
          # Accepts full (6-digit) and short (3-digit) hex formats,
          # with or without the # prefix. Also supports 8-digit (with alpha)
          # and 4-digit short format with alpha.
          #
          # @param input [String] The hex color string to parse
          # @return [RGB] The parsed RGB color
          # @raise [ParseError] If the input is not a valid hex color
          #
          # @example Full format with hash
          #   Unmagic::Color::RGB::Hex.parse("#FF8800")
          #
          # @example Short format without hash
          #   Unmagic::Color::RGB::Hex.parse("F80")
          #
          # @example With alpha
          #   Unmagic::Color::RGB::Hex.parse("#FF880080")
          def parse(input)
            raise ParseError, "Input must be a string" unless input.is_a?(::String)

            # Clean up the input
            hex = input.strip.gsub(/^#/, "")

            # Check for valid length (3, 4, 6, or 8 characters)
            unless [3, 4, 6, 8].include?(hex.length)
              raise ParseError, "Invalid number of characters (got #{hex.length}, expected 3, 4, 6, or 8)"
            end

            # Check if all characters are valid hex digits
            unless hex.match?(/\A[0-9A-Fa-f]+\z/)
              invalid_chars = hex.chars.reject { |c| c.match?(/[0-9A-Fa-f]/) }
              raise ParseError, "Invalid hex characters: #{invalid_chars.join(", ")}"
            end

            # Handle 3 or 4-character hex codes (expand each digit)
            if hex.length == 3 || hex.length == 4
              hex = hex.chars.map { |c| c * 2 }.join
            end

            r = hex[0..1].to_i(16)
            g = hex[2..3].to_i(16)
            b = hex[4..5].to_i(16)

            # Parse alpha if present (8 characters total after expansion)
            if hex.length == 8
              a = hex[6..7].to_i(16)
              # Convert 0-255 alpha to 0-100 percentage
              alpha_percent = (a / 255.0 * 100).round(2)
              RGB.build(red: r, green: g, blue: b, alpha: alpha_percent)
            else
              RGB.build(red: r, green: g, blue: b)
            end
          end
        end
      end
    end
  end
end
