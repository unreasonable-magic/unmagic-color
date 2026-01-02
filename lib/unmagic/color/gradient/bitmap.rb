# frozen_string_literal: true

module Unmagic
  class Color
    module Gradient
      # A 2D grid of color pixels representing a rasterized gradient.
      #
      # Bitmap represents the output of gradient rasterization as a grid of colors.
      # For linear gradients, this is a single row (height=1). The 2D structure
      # allows for future gradient types that need multiple rows.
      #
      # ## Pixel Storage
      #
      # Pixels are stored as a 2D array: `pixels[y][x] = color`
      #
      # - Linear gradients: `pixels = [[color1, color2, ...]]` (single row)
      # - Multi-row gradients: `pixels = [[row1...], [row2...], ...]`
      #
      # ## Examples
      #
      #   # Create a 1D bitmap (from linear gradient)
      #   bitmap = Unmagic::Color::Gradient::Bitmap.new(
      #     width: 5,
      #     height: 1,
      #     pixels: [[red, orange, yellow, green, blue]]
      #   )
      #
      #   # Access pixels
      #   bitmap.at(0, 0)  # => red (first pixel)
      #   bitmap.at(4, 0)  # => blue (last pixel)
      #   bitmap[]         # => red (shortcut for first pixel)
      #
      #   # Convert to flat array
      #   bitmap.to_a   # => [red, orange, yellow, green, blue]
      class Bitmap
        attr_reader :width, :height, :pixels

        # Create a new bitmap.
        #
        # @param width [Integer] Number of pixels horizontally
        # @param height [Integer] Number of pixels vertically
        # @param pixels [Array<Array<Color>>] 2D array of colors (pixels[y][x])
        def initialize(width:, height:, pixels:)
          @width = width
          @height = height
          @pixels = pixels
        end

        # Access a pixel at the given coordinates.
        #
        # @param x [Integer] Horizontal position (0 to width-1)
        # @param y [Integer] Vertical position (0 to height-1), defaults to 0
        # @return [Color] The color at the specified position
        def at(x, y = 0)
          @pixels[y][x]
        end

        # Shortcut to access a pixel.
        #
        # When called without arguments, returns the first pixel (0, 0).
        # When called with arguments, delegates to `at`.
        #
        # @param args [Array] Optional x and y coordinates
        # @return [Color] The color at the specified position
        #
        # @example Get first pixel
        #   bitmap[]  # => color at (0, 0)
        #
        # @example Get specific pixel
        #   bitmap[5, 0]  # => color at (5, 0)
        def [](*args)
          if args.empty?
            at(0, 0)
          else
            at(*args)
          end
        end

        # Convert to a flat 1D array of colors.
        #
        # Flattens the 2D pixel grid into a single array, reading left-to-right,
        # top-to-bottom.
        #
        # @return [Array<Color>] Flattened array of all colors
        def to_a
          @pixels.flatten
        end
      end
    end
  end
end
