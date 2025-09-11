# frozen_string_literal: true

require "unmagic/support/percentage"

module Unmagic
  class Color
    class Error < StandardError; end
    class ParseError < Error; end

    require_relative "color/rgb"
    require_relative "color/rgb/hex"
    require_relative "color/hsl"
    require_relative "color/oklch"

    class << self
      def parse(input)
        return input if input.is_a?(self)
        raise ParseError.new("Can't pass nil as a color") if input.nil?

        input = input.strip
        raise ParseError.new("Can't parse empty string") if input == ""

        # Try hex or RGB format
        if input.start_with?("#") || input.match?(/\A[0-9A-Fa-f]{3,6}\z/) || input.start_with?("rgb")
          RGB.parse(input)
        elsif input.start_with?("hsl")
          HSL.parse(input)
        elsif input.start_with?("oklch")
          OKLCH.parse(input)
        else
          raise ParseError.new("Unknown color #{input.inspect}")
        end
      end

      def [](value)
        parse(value)
      end
    end

    # Base unit for RGB components (0-255)
    Component = Data.define(:value) do
      def initialize(value:)
        super(value: value.to_i.clamp(0, 255))
      end

      def to_i = value
      def to_f = value.to_f

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
    end

    Red = Component
    Green = Component
    Blue = Component

    # Angular unit for hue (0-360 degrees, wrapping)
    Hue = Data.define(:value) do
      def initialize(value:)
        super(value: value.to_f % 360)
      end

      def to_f = value
      def degrees = value

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
    end

    # OKLCH chroma unit (0-0.5)
    Chroma = Data.define(:value) do
      def initialize(value:)
        super(value: value.to_f.clamp(0, 0.5))
      end

      def to_f = value

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
    end

    # Percentage-based units
    class Saturation < Unmagic::Support::Percentage; end
    class Lightness < Unmagic::Support::Percentage; end

    # Convert to RGB representation
    def to_rgb
      raise NotImplementedError
    end

    # Convert to HSL representation
    def to_hsl
      raise NotImplementedError
    end

    # Convert to OKLCH representation
    def to_oklch
      raise NotImplementedError
    end

    # Calculate perceptual luminance (0.0 to 1.0)
    def luminance
      raise NotImplementedError
    end

    # Blend with another color
    def blend(other, amount = 0.5)
      raise NotImplementedError
    end

    # Create a lighter version of this color
    def lighten(amount = 0.1)
      raise NotImplementedError
    end

    # Create a darker version of this color
    def darken(amount = 0.1)
      raise NotImplementedError
    end

    # Determine if this is a light color
    def light?
      luminance > 0.5
    end

    # Determine if this is a dark color
    def dark?
      !light?
    end
  end
end
