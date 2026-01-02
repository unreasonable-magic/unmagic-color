# frozen_string_literal: true

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
    # ## Examples
    #
    #   # Auto-detect color space, auto-balance positions
    #   gradient = Unmagic::Color::Gradient.linear(["#FF0000", "#0000FF"])
    #   bitmap = gradient.rasterize(width: 10)
    #
    #   # Or use explicit positions
    #   gradient = Unmagic::Color::Gradient.linear([["#FF0000", 0.0], ["#0000FF", 1.0]])
    #   bitmap = gradient.rasterize(width: 10)
    #
    #   # Works with HSL and OKLCH too
    #   gradient = Unmagic::Color::Gradient.linear(["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"])
    #   bitmap = gradient.rasterize(width: 10)
    #
    #   # Three colors are evenly spaced (0.0, 0.5, 1.0)
    #   gradient = Unmagic::Color::Gradient.linear(["#FF0000", "#00FF00", "#0000FF"])
    #
    #   # Rasterize the same gradient at different resolutions
    #   colors = gradient.rasterize(width: 5).pixels[0]   # 5 colors
    #   colors = gradient.rasterize(width: 100).pixels[0] # 100 colors
    #
    #   # Angled gradients
    #   gradient = Unmagic::Color::Gradient.linear("45deg", ["#FF0000", "#0000FF"])
    #   bitmap = gradient.rasterize(width: 10, height: 10)
    #
    #   # Direction keywords
    #   gradient = Unmagic::Color::Gradient.linear("to right", ["#FF0000", "#0000FF"])
    #   bitmap = gradient.rasterize(width: 10, height: 1)
    module Gradient
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
        # Supports optional direction parameter (like CSS):
        # - Angle in degrees: "45deg", "90deg", etc.
        # - Direction keywords: "to top", "to right", "to bottom left", etc.
        # - If omitted, defaults to "to bottom" (180deg)
        #
        # String detection:
        # - Strings starting with "hsl(" use HSL color space
        # - Strings starting with "oklch(" use OKLCH color space
        # - All other strings (hex, rgb()) use RGB color space
        #
        # Color object detection:
        # - Uses the class of the color object directly
        #
        # @param args [Array] Optional direction followed by colors or [color, position] pairs
        # @return [Linear] A gradient instance in the detected color space
        #
        # @example Simple gradient
        #   Gradient.linear(["#FF0000", "#0000FF"])
        #
        # @example With angle (CSS-style)
        #   Gradient.linear("45deg", ["#FF0000", "#0000FF"])
        #
        # @example With direction (CSS-style)
        #   Gradient.linear("to right", ["blue", "red"])
        #
        # @example Mixed positions (like CSS linear-gradient)
        #   Gradient.linear(["#FF0000", ["#FFFF00", 0.3], "#00FF00", ["#0000FF", 0.9], "#FF00FF"])
        def linear(*args)
          # Parse optional direction argument
          direction = nil
          colors_or_tuples = args

          # Check if first argument is a direction
          first_arg = args.first
          if first_arg.is_a?(::Numeric)
            # Numeric direction (degrees)
            direction = args.shift
            colors_or_tuples = args
          elsif first_arg.is_a?(::String) && (first_arg.match?(/deg$/) || first_arg.match?(/^to /))
            # String direction (e.g., "45deg", "to right")
            direction = args.shift
            colors_or_tuples = args
          end

          # If only one argument and it's an array, use it as colors
          if colors_or_tuples.length == 1 && colors_or_tuples.first.is_a?(::Array)
            colors_or_tuples = colors_or_tuples.first
          end

          raise Error, "colors must have at least one color" if colors_or_tuples.empty?

          # Extract first color for color space detection (handle both positioned and non-positioned)
          first = colors_or_tuples.first
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

          gradient_class.build(colors_or_tuples, direction: direction)
        end
      end
    end
  end
end
