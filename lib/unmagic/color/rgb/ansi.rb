# frozen_string_literal: true

module Unmagic
  class Color
    class RGB
      # ANSI SGR (Select Graphic Rendition) color code parsing.
      #
      # Parses ANSI color codes used in terminal output. Handles standard 3/4-bit colors,
      # 256-color palette, and 24-bit true color formats.
      #
      # ## Supported Formats
      #
      # Standard 3/4-bit colors (foreground and background):
      #
      #     Unmagic::Color::RGB::ANSI.parse("31")        # Red foreground
      #     Unmagic::Color::RGB::ANSI.parse("41")        # Red background
      #     Unmagic::Color::RGB::ANSI.parse("91")        # Bright red foreground
      #     Unmagic::Color::RGB::ANSI.parse("101")       # Bright red background
      #
      # 256-color palette:
      #
      #     Unmagic::Color::RGB::ANSI.parse("38;5;196")  # Red foreground (256-color)
      #     Unmagic::Color::RGB::ANSI.parse("48;5;196")  # Red background (256-color)
      #
      # 24-bit true color:
      #
      #     Unmagic::Color::RGB::ANSI.parse("38;2;255;0;0")    # Red foreground (true color)
      #     Unmagic::Color::RGB::ANSI.parse("48;2;255;0;0")    # Red background (true color)
      #
      # @example Parse standard ANSI color
      #   Unmagic::Color::RGB::ANSI.parse("31")
      #   #=> RGB instance for red
      #
      # @example Parse 24-bit true color
      #   Unmagic::Color::RGB::ANSI.parse("38;2;100;150;200")
      #   #=> RGB instance for RGB(100, 150, 200)
      class ANSI
        # Error raised when parsing ANSI color codes fails
        class ParseError < Color::Error; end

        class << self
          # Check if a string or integer is a valid ANSI color code.
          #
          # @param value [String, Integer] The value to validate
          # @return [Boolean] true if valid ANSI code, false otherwise
          #
          # @example Check string
          #   Unmagic::Color::RGB::ANSI.valid?("31")
          #   #=> true
          #
          # @example Check integer
          #   Unmagic::Color::RGB::ANSI.valid?(31)
          #   #=> true
          #
          # @example Invalid input
          #   Unmagic::Color::RGB::ANSI.valid?("invalid")
          #   #=> false
          def valid?(value)
            parse(value)
            true
          rescue ParseError
            false
          end

          # Parse an ANSI SGR color code.
          #
          # Accepts SGR parameters only (not full escape sequences).
          # Handles foreground and background colors in all formats.
          # Integers are automatically converted to strings.
          #
          # @param input [String, Integer] The ANSI code to parse
          # @return [RGB] The parsed RGB color
          # @raise [ParseError] If the input is not a valid ANSI color code
          #
          # @example Parse standard ANSI color with string
          #   Unmagic::Color::RGB::ANSI.parse("31")
          #   #=> Unmagic::Color::RGB instance for red
          #
          # @example Parse standard ANSI color with integer
          #   Unmagic::Color::RGB::ANSI.parse(31)
          #   #=> Unmagic::Color::RGB instance for red
          #
          # @example Parse 256-color palette
          #   Unmagic::Color::RGB::ANSI.parse("38;5;196")
          #   #=> Unmagic::Color::RGB instance for bright red
          #
          # @example Parse 24-bit true color
          #   color = Unmagic::Color::RGB::ANSI.parse("38;2;100;150;200")
          #   color.to_hex
          #   #=> "#6496c8"
          def parse(input)
            raise ParseError, "Input must be a string or integer" unless input.is_a?(::String) || input.is_a?(::Integer)

            # Convert integers to strings
            input = input.to_s if input.is_a?(::Integer)

            # Strip and validate format
            clean = input.strip
            raise ParseError, "Can't parse empty string" if clean.empty?

            # Must be numeric with optional semicolons
            unless clean.match?(/\A\d+(?:;\d+)*\z/)
              raise ParseError, "Invalid ANSI format: #{input.inspect} (must be numeric with optional semicolons)"
            end

            # Split on semicolons
            parts = clean.split(";").map(&:to_i)

            parse_sgr_params(parts)
          end

          private

          # Parse SGR parameters and return RGB color
          def parse_sgr_params(parts)
            first = parts[0]

            # Check for extended color formats (38 or 48 prefix)
            if first == 38 || first == 48
              parse_extended_color(parts)
            # Check for standard 3/4-bit colors
            elsif standard_color?(first)
              parse_standard_color(first)
            else
              raise ParseError, "Unknown ANSI color code: #{parts.join(";")}"
            end
          end

          # Parse extended color formats (256-color or true color)
          def parse_extended_color(parts)
            raise ParseError, "Extended color format requires at least 3 parameters" if parts.length < 3

            color_type = parts[1]

            case color_type
            when 5
              # 256-color palette: 38;5;N or 48;5;N
              parse_256_color(parts)
            when 2
              # 24-bit true color: 38;2;R;G;B or 48;2;R;G;B
              parse_true_color(parts)
            else
              raise ParseError, "Unknown extended color type: #{color_type} (expected 2 for true color or 5 for 256-color)"
            end
          end

          # Parse 256-color palette code
          def parse_256_color(parts)
            raise ParseError, "256-color format requires 3 parameters (e.g., 38;5;N)" unless parts.length == 3

            index = parts[2]

            if index < 0 || index > 255
              raise ParseError, "256-color index must be 0-255, got #{index}"
            end

            color_256_to_rgb(index)
          end

          # Parse 24-bit true color code
          def parse_true_color(parts)
            raise ParseError, "True color format requires 5 parameters (e.g., 38;2;R;G;B)" unless parts.length == 5

            r = parts[2]
            g = parts[3]
            b = parts[4]

            # Validate RGB ranges
            [r, g, b].each_with_index do |val, i|
              component = ["red", "green", "blue"][i]
              if val < 0 || val > 255
                raise ParseError, "#{component.capitalize} must be 0-255, got #{val}"
              end
            end

            RGB.new(red: r, green: g, blue: b)
          end

          # Check if code is a standard 3/4-bit color
          def standard_color?(code)
            # Foreground: 30-37 (normal), 90-97 (bright)
            # Background: 40-47 (normal), 100-107 (bright)
            (30..37).cover?(code) || (40..47).cover?(code) ||
              (90..97).cover?(code) || (100..107).cover?(code)
          end

          # Parse standard 3/4-bit color code
          def parse_standard_color(code)
            # Extract color index (0-7)
            index = if (30..37).cover?(code)
              code - 30
            elsif (40..47).cover?(code)
              code - 40
            elsif (90..97).cover?(code)
              code - 90
            elsif (100..107).cover?(code)
              code - 100
            end

            standard_color_to_rgb(index)
          end

          # Convert standard color index to RGB
          # Using bright ANSI colors for consistency
          def standard_color_to_rgb(index)
            case index
            when 0 then RGB.new(red: 0, green: 0, blue: 0)         # black
            when 1 then RGB.new(red: 255, green: 0, blue: 0)       # red
            when 2 then RGB.new(red: 0, green: 255, blue: 0)       # green
            when 3 then RGB.new(red: 255, green: 255, blue: 0)     # yellow
            when 4 then RGB.new(red: 0, green: 0, blue: 255)       # blue
            when 5 then RGB.new(red: 255, green: 0, blue: 255)     # magenta
            when 6 then RGB.new(red: 0, green: 255, blue: 255)     # cyan
            when 7 then RGB.new(red: 255, green: 255, blue: 255)   # white
            else
              raise ParseError, "Invalid color index: #{index}"
            end
          end

          # Convert 256-color palette index to RGB
          def color_256_to_rgb(index)
            case index
            when 0..15
              # Standard colors (use same as 3/4-bit)
              standard_color_to_rgb(index % 8)
            when 16..231
              # 6x6x6 RGB cube
              index -= 16
              r = (index / 36) * 51
              g = ((index % 36) / 6) * 51
              b = (index % 6) * 51
              RGB.new(red: r, green: g, blue: b)
            when 232..255
              # Grayscale ramp
              gray = 8 + (index - 232) * 10
              RGB.new(red: gray, green: gray, blue: gray)
            else
              raise ParseError, "Invalid 256-color index: #{index}"
            end
          end
        end
      end
    end
  end
end
