# frozen_string_literal: true

# @private
module Unmagic
  # Base class for working with colors in different color spaces.
  #
  # Understanding Colors
  #
  # A color is simply a way to describe what we see. Just like you can describe
  # a location using different coordinate systems (street address, latitude/longitude, etc.),
  # you can describe colors using different "color spaces."
  #
  # This library supports three main color spaces:
  #
  # - RGB: Describes colors as a mix of Red, Green, and Blue light (like your screen)
  # - HSL: Describes colors using Hue (color wheel position), Saturation (intensity),
  #   and Lightness (brightness)
  # - OKLCH: A modern color space that matches how humans perceive color differences
  #
  # Basic Usage
  #
  # Parse a color from a string:
  #
  #   color = Color.parse("#FF5733")
  #   color = Color["rgb(255, 87, 51)"]
  #   color = Color.parse("hsl(9, 100%, 60%)")
  #
  # Convert between color spaces:
  #
  #   rgb = Color.parse("#FF5733")
  #   hsl = rgb.to_hsl
  #   oklch = rgb.to_oklch
  #
  # Manipulate colors:
  #
  #   lighter = color.lighten(0.2)
  #   darker = color.darken(0.1)
  #   mixed = color.blend(other_color, 0.5)
  class Color
    # @private
    class Error < StandardError; end
    # @private
    class ParseError < Error; end

    require_relative "color/rgb"
    require_relative "color/rgb/hex"
    require_relative "color/hsl"
    require_relative "color/oklch"
    require_relative "color/string/hash_function"
    require_relative "color/util/percentage"

    class << self
      # Parse a color string into the appropriate color space object.
      #
      # This method automatically detects the format and returns the correct color type.
      # Supported formats include hex colors, RGB, HSL, and OKLCH.
      #
      # @param input [String, Color] The color string to parse, or an existing Color object
      # @return [RGB, HSL, OKLCH] A color object in the appropriate color space
      # @raise [ParseError] If the input is nil, empty, or in an unrecognized format
      #
      # @example Parse a hex color
      #   Unmagic::Color.parse("#FF5733")
      #
      # @example Parse an RGB color
      #   Unmagic::Color.parse("rgb(255, 87, 51)")
      #
      # @example Parse an HSL color
      #   Unmagic::Color.parse("hsl(9, 100%, 60%)")
      #
      # @example Parse an OKLCH color
      #   Unmagic::Color.parse("oklch(0.65 0.15 30)")
      #
      # @example Pass through an existing color
      #   color = Unmagic::Color.parse("#FF5733")
      #   Unmagic::Color.parse(color)
      def parse(input)
        return input if input.is_a?(self)
        raise ParseError, "Can't pass nil as a color" if input.nil?

        input = input.strip
        raise ParseError, "Can't parse empty string" if input == ""

        # Try hex or RGB format
        if input.start_with?("#") || input.match?(/\A[0-9A-Fa-f]{3,6}\z/) || input.start_with?("rgb")
          RGB.parse(input)
        elsif input.start_with?("hsl")
          HSL.parse(input)
        elsif input.start_with?("oklch")
          OKLCH.parse(input)
        else
          raise ParseError, "Unknown color #{input.inspect}"
        end
      end

      # Parse a color string using bracket notation.
      #
      # This is a convenient alias for {parse}.
      #
      # @param value [String, Color] The color string to parse
      # @return [RGB, HSL, OKLCH] A color object in the appropriate color space
      # @raise [ParseError] If the input is invalid
      #
      # @example
      #   Unmagic::Color["#FF5733"]
      #   Unmagic::Color["hsl(9, 100%, 60%)"]
      def [](value)
        parse(value)
      end
    end

    # Base unit for RGB components (0-255)
    # @private
    Component = Data.define(:value) do
      include Comparable

      def initialize(value:)
        super(value: value.to_i.clamp(0, 255))
      end

      def to_i = value
      def to_f = value.to_f

      def <=>(other)
        case other
        when Component, Numeric
          value <=> other.to_f
        end
      end

      # Arithmetic operations that return new instances
      def *(other)
        self.class.new(value: value * other.to_f)
      end

      def /(other)
        self.class.new(value: value / other.to_f)
      end

      def +(other)
        self.class.new(value: value + other.to_f)
      end

      def -(other)
        self.class.new(value: value - other.to_f)
      end

      def abs
        self.class.new(value: value.abs)
      end
    end

    # @private
    Red = Component
    # @private
    Green = Component
    # @private
    Blue = Component

    # Angular unit for hue (0-360 degrees, wrapping)
    # @private
    Hue = Data.define(:value) do
      include Comparable

      def initialize(value:)
        super(value: value.to_f % 360)
      end

      def to_f = value
      def degrees = value

      def <=>(other)
        case other
        when Hue, Numeric
          value <=> other.to_f
        end
      end

      # Arithmetic operations that return new instances
      def *(other)
        self.class.new(value: value * other.to_f)
      end

      def /(other)
        self.class.new(value: value / other.to_f)
      end

      def +(other)
        self.class.new(value: value + other.to_f)
      end

      def -(other)
        self.class.new(value: value - other.to_f)
      end

      def abs
        self.class.new(value: value.abs)
      end
    end

    # OKLCH chroma unit (0-0.5)
    # @private
    Chroma = Data.define(:value) do
      include Comparable

      def initialize(value:)
        super(value: value.to_f.clamp(0, 0.5))
      end

      def to_f = value

      def <=>(other)
        case other
        when Chroma, Numeric
          value <=> other.to_f
        end
      end

      # Arithmetic operations that return new instances
      def *(other)
        self.class.new(value: value * other.to_f)
      end

      def /(other)
        self.class.new(value: value / other.to_f)
      end

      def +(other)
        self.class.new(value: value + other.to_f)
      end

      def -(other)
        self.class.new(value: value - other.to_f)
      end

      def abs
        self.class.new(value: value.abs)
      end
    end

    # Percentage-based units
    # @private
    class Saturation < Unmagic::Util::Percentage; end
    # @private
    class Lightness < Unmagic::Util::Percentage; end

    # Convert this color to RGB color space.
    #
    # RGB represents colors as a combination of Red, Green, and Blue light,
    # with each component ranging from 0-255.
    #
    # @return [RGB] The color in RGB color space
    def to_rgb
      raise NotImplementedError
    end

    # Convert this color to HSL color space.
    #
    # HSL represents colors using Hue (0-360°), Saturation (0-100%),
    # and Lightness (0-100%).
    #
    # @return [HSL] The color in HSL color space
    def to_hsl
      raise NotImplementedError
    end

    # Convert this color to OKLCH color space.
    #
    # OKLCH is a perceptually uniform color space that better matches
    # how humans perceive color differences.
    #
    # @return [OKLCH] The color in OKLCH color space
    def to_oklch
      raise NotImplementedError
    end

    # Calculate the perceptual luminance of this color.
    #
    # Luminance represents how bright the color appears to the human eye,
    # accounting for the fact that we perceive green as brighter than red,
    # and red as brighter than blue.
    #
    # @return [Float] The luminance value from 0.0 (black) to 1.0 (white)
    def luminance
      raise NotImplementedError
    end

    # Blend this color with another color.
    #
    # Creates a new color by mixing this color with another. The amount
    # parameter controls how much of the other color to mix in.
    #
    # @param other [Color] The color to blend with
    # @param amount [Float] How much of the other color to use (0.0 to 1.0)
    # @return [Color] A new color that is a blend of the two colors
    #
    # @example Mix two colors equally
    #   red = Unmagic::Color.parse("#FF0000")
    #   blue = Unmagic::Color.parse("#0000FF")
    #   red.blend(blue, 0.5)
    #
    # @example Add a hint of another color
    #   base = Unmagic::Color.parse("#336699")
    #   base.blend(Unmagic::Color.parse("#FF0000"), 0.1)
    def blend(other, amount = 0.5)
      raise NotImplementedError
    end

    # Create a lighter version of this color.
    #
    # Returns a new color that is lighter than the original. The exact
    # implementation depends on the color space.
    #
    # @param amount [Float] How much to lighten (0.0 to 1.0)
    # @return [Color] A new, lighter color
    #
    # @example Make a color 20% lighter
    #   dark = Unmagic::Color.parse("#336699")
    #   dark.lighten(0.2)
    def lighten(amount = 0.1)
      raise NotImplementedError
    end

    # Create a darker version of this color.
    #
    # Returns a new color that is darker than the original. The exact
    # implementation depends on the color space.
    #
    # @param amount [Float] How much to darken (0.0 to 1.0)
    # @return [Color] A new, darker color
    #
    # @example Make a color 10% darker
    #   bright = Unmagic::Color.parse("#FF9966")
    #   bright.darken(0.1)
    def darken(amount = 0.1)
      raise NotImplementedError
    end

    # Check if this is a light color.
    #
    # A color is considered light if its luminance is greater than 0.5.
    # This is useful for determining whether to use dark or light text
    # on a colored background.
    #
    # @return [Boolean] true if the color is light, false otherwise
    #
    # @example Choose text color based on background
    #   bg = Unmagic::Color.parse("#FFFF00")  # Yellow
    #   text_color = bg.light? ? "#000000" : "#FFFFFF"
    #   # => "#000000"
    def light?
      luminance > 0.5
    end

    # Check if this is a dark color.
    #
    # A color is considered dark if its luminance is 0.5 or less.
    # This is the opposite of {#light?}.
    #
    # @return [Boolean] true if the color is dark, false otherwise
    def dark?
      !light?
    end
  end
end
