# frozen_string_literal: true

require_relative "units/direction"

module Unmagic
  class Color
    # Gradient generation for smooth color transitions.
    #
    # Provides classes for creating linear color gradients in RGB, HSL, or
    # OKLCH color spaces.
    #
    # ## Core Classes
    #
    # - {Stop} - Represents a color at a specific position
    # - {Bitmap} - A 2D grid of colors (output from rasterization)
    # - {Base} - Base class for gradient implementations
    #
    # ## Gradient Types
    #
    # - `RGB::Gradient::Linear` - Linear gradient in RGB space
    # - `HSL::Gradient::Linear` - Linear gradient in HSL space
    # - `OKLCH::Gradient::Linear` - Linear gradient in OKLCH space
    #
    # @example Auto-detect color space, auto-balance positions
    #   gradient = Unmagic::Color::Gradient.linear(["#FF0000", "#0000FF"])
    #   bitmap = gradient.rasterize(width: 10)
    #
    # @example Use explicit positions
    #   gradient = Unmagic::Color::Gradient.linear([["#FF0000", 0.0], ["#0000FF", 1.0]])
    #   bitmap = gradient.rasterize(width: 10)
    #
    # @example Works with HSL and OKLCH too
    #   gradient = Unmagic::Color::Gradient.linear(["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"])
    #   bitmap = gradient.rasterize(width: 10)
    #
    # @example Three colors are evenly spaced (0.0, 0.5, 1.0)
    #   gradient = Unmagic::Color::Gradient.linear(["#FF0000", "#00FF00", "#0000FF"])
    #
    # @example Rasterize at different resolutions
    #   colors = gradient.rasterize(width: 5).pixels[0]   # 5 colors
    #   colors = gradient.rasterize(width: 100).pixels[0] # 100 colors
    #
    # @example Angled gradients
    #   gradient = Unmagic::Color::Gradient.linear(["#FF0000", "#0000FF"], direction: "45deg")
    #   bitmap = gradient.rasterize(width: 10, height: 10)
    #
    # @example Direction keywords
    #   gradient = Unmagic::Color::Gradient.linear(["#FF0000", "#0000FF"], direction: "to right")
    #   bitmap = gradient.rasterize(width: 10, height: 1)
    module Gradient
      # Base error class for gradient-related errors.
      class Error < Color::Error; end

      class << self
        # Create a linear gradient, auto-detecting color space from input.
        #
        # Examines the first color to determine which color space to use (RGB, HSL, or OKLCH),
        # then delegates to the appropriate Linear gradient class.
        #
        # Works like CSS linear-gradient - you can mix positioned and non-positioned colors.
        # Non-positioned colors auto-balance between their surrounding positioned neighbors.
        #
        # Color space detection:
        # - Strings starting with "hsl(" use HSL color space
        # - Strings starting with "oklch(" use OKLCH color space
        # - All other strings (hex, rgb()) use RGB color space
        # - Color objects use their class directly
        #
        # @param colors [Array] Colors or [color, position] pairs
        # @param direction [String, Numeric, Degrees, Direction, nil] Optional gradient direction
        #   - Direction strings: "to top", "from left to right", "45deg", "90°"
        #   - Numeric degrees: 45, 90, 180
        #   - Degrees/Direction instances
        #   - Defaults to "to bottom" (180°) if omitted
        # @return [Linear] A gradient instance in the detected color space
        #
        # @example Simple gradient
        #   Gradient.linear(["#FF0000", "#0000FF"])
        #
        # @example With direction keyword
        #   Gradient.linear(["#FF0000", "#0000FF"], direction: "to right")
        #   Gradient.linear(["blue", "red"], direction: "from left to right")
        #
        # @example With numeric direction
        #   Gradient.linear(["#FF0000", "#0000FF"], direction: 45)
        #   Gradient.linear(["#FF0000", "#0000FF"], direction: "90°")
        #
        # @example Mixed positions (like CSS linear-gradient)
        #   Gradient.linear(["#FF0000", ["#FFFF00", 0.3], "#00FF00", ["#0000FF", 0.9], "#FF00FF"])
        def linear(colors, direction: nil)
          # Convert direction to Direction instance
          direction_instance = if direction.nil?
            # Default to "to bottom" (CSS default)
            Unmagic::Color::Units::Degrees::Direction::TOP_TO_BOTTOM
          elsif direction.is_a?(Unmagic::Color::Units::Degrees::Direction)
            direction
          elsif direction.is_a?(Unmagic::Color::Units::Degrees)
            # Degrees instance - convert to Direction (from opposite to this degree)
            Unmagic::Color::Units::Degrees::Direction.new(from: direction.opposite, to: direction)
          elsif direction.is_a?(::Numeric)
            # Numeric - convert to Degrees, then to Direction
            degrees = Unmagic::Color::Units::Degrees.new(value: direction)
            Unmagic::Color::Units::Degrees::Direction.new(from: degrees.opposite, to: degrees)
          elsif direction.is_a?(::String)
            # String - parse as Direction or Degrees
            if Unmagic::Color::Units::Degrees::Direction.matches?(direction)
              Unmagic::Color::Units::Degrees::Direction.parse(direction)
            else
              degrees = Unmagic::Color::Units::Degrees.parse(direction)
              Unmagic::Color::Units::Degrees::Direction.new(from: degrees.opposite, to: degrees)
            end
          else
            raise Error, "Invalid direction type: #{direction.class}"
          end

          raise Error, "colors must have at least one color" if colors.empty?

          # Extract first color for color space detection (handle both positioned and non-positioned)
          first = colors.first
          first_color_or_string = first.is_a?(::Array) ? first.first : first

          # Determine color class from first color
          color_class = if first_color_or_string.is_a?(Unmagic::Color)
            first_color_or_string.class
          elsif first_color_or_string.is_a?(::String)
            if first_color_or_string.match?(/^\s*hsl\s*\(/)
              Unmagic::Color::HSL
            elsif first_color_or_string.match?(/^\s*oklch\s*\(/)
              Unmagic::Color::OKLCH
            else
              Unmagic::Color::RGB
            end
          else
            raise Error, "First color must be a Color instance or String"
          end

          # Delegate to appropriate Linear class
          gradient_class = case color_class.name
          when "Unmagic::Color::RGB"
            Unmagic::Color::RGB::Gradient::Linear
          when "Unmagic::Color::HSL"
            Unmagic::Color::HSL::Gradient::Linear
          when "Unmagic::Color::OKLCH"
            Unmagic::Color::OKLCH::Gradient::Linear
          else
            raise Error, "Unsupported color class: #{color_class}"
          end

          gradient_class.build(colors, direction: direction_instance)
        end
      end
    end
  end
end
