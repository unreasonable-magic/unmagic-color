# frozen_string_literal: true

module Unmagic
  # Base class for color representations
  class Color
    # Parse a color string and return the appropriate Color object
    def self.parse(input)
      return nil unless input.is_a?(String)

      input = input.strip

      # Try hex first (most common)
      if input.start_with?("#") || input.match?(/\A[0-9A-Fa-f]{3,6}\z/)
        Unmagic::Color::Hex.parse(input)
      # RGB format
      elsif input.start_with?("rgb")
        Unmagic::Color::RGB.parse(input)
      # HSL format
      elsif input.start_with?("hsl")
        Unmagic::Color::HSL.parse(input)
      # Try as hex without #
      elsif input.match?(/\A[0-9A-Fa-f]{6}\z/)
        Unmagic::Color::Hex.parse(input)
      else
        nil
      end
    end

    # Create a color from HSL values
    def self.from_hsl(hue, saturation, lightness)
      Unmagic::Color::HSL.new(hue: hue, saturation: saturation, lightness: lightness)
    end

    # Convenience constructor that accepts hex strings or Color objects
    def self.new(input = nil, **kwargs)
      if input.is_a?(String)
        parse(input) || super(**kwargs)
      elsif input.is_a?(Color)
        input
      elsif input.nil? && !kwargs.empty?
        super(**kwargs)
      elsif input.is_a?(Hash)
        super(**input)
      else
        super(red: 0, green: 0, blue: 0)
      end
    end

    attr_reader :red, :green, :blue

    def initialize(red:, green:, blue:)
      @red = red.to_i.clamp(0, 255)
      @green = green.to_i.clamp(0, 255)
      @blue = blue.to_i.clamp(0, 255)
    end

    # Convert to RGB representation
    def to_rgb
      Unmagic::Color::RGB.new(red: @red, green: @green, blue: @blue)
    end

    # Convert to hex string
    def to_hex
      "#%02x%02x%02x" % [ @red, @green, @blue ]
    end

    # Convert to HSL
    def to_hsl
      r = @red / 255.0
      g = @green / 255.0
      b = @blue / 255.0

      max = [ r, g, b ].max
      min = [ r, g, b ].min
      delta = max - min

      # Lightness
      l = (max + min) / 2.0

      if delta == 0
        # Achromatic
        h = 0
        s = 0
      else
        # Saturation
        s = l > 0.5 ? delta / (2.0 - max - min) : delta / (max + min)

        # Hue
        h = case max
        when r then ((g - b) / delta + (g < b ? 6 : 0)) / 6.0
        when g then ((b - r) / delta + 2) / 6.0
        when b then ((r - g) / delta + 4) / 6.0
        end
      end

      Unmagic::Color::HSL.new(hue: (h * 360).round, saturation: (s * 100).round, lightness: (l * 100).round)
    end

    # Get hue component (0-360)
    def hue
      to_hsl.hue
    end

    # Get saturation component (0-100)
    def saturation
      to_hsl.saturation
    end

    # Get lightness component (0-100)
    def lightness
      to_hsl.lightness
    end

    # Alias for to_hex for convenience
    def hex
      to_hex
    end

    # Calculate relative luminance (for contrast calculations)
    def luminance
      r = @red / 255.0
      g = @green / 255.0
      b = @blue / 255.0

      r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) ** 2.4
      g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) ** 2.4
      b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) ** 2.4

      0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    # Blend with another color
    def blend(other, amount = 0.5)
      amount = amount.to_f.clamp(0, 1)
      other_rgb = other.to_rgb

      Unmagic::Color::RGB.new(
        red: (@red * (1 - amount) + other_rgb.red * amount).round,
        green: (@green * (1 - amount) + other_rgb.green * amount).round,
        blue: (@blue * (1 - amount) + other_rgb.blue * amount).round
      )
    end

    # Lighten by blending with white
    def lighten(amount = 0.1)
      blend(Unmagic::Color::RGB.new(red: 255, green: 255, blue: 255), amount)
    end

    # Darken by blending with black
    def darken(amount = 0.1)
      blend(Unmagic::Color::RGB.new(red: 0, green: 0, blue: 0), amount)
    end

    # Determine if this is a light or dark color
    def light?
      luminance > 0.5
    end

    def dark?
      !light?
    end

    # Get contrasting color (black or white)
    def contrast_color
      light? ? Unmagic::Color::RGB.new(red: 0, green: 0, blue: 0) : Unmagic::Color::RGB.new(red: 255, green: 255, blue: 255)
    end

    # Calculate WCAG contrast ratio with another color
    def contrast_ratio(other)
      other = Unmagic::Color.parse(other) if other.is_a?(String)
      return 1.0 unless other

      l1 = luminance
      l2 = other.luminance

      lighter = [ l1, l2 ].max
      darker = [ l1, l2 ].min

      (lighter + 0.05) / (darker + 0.05)
    end

    # Adjust this color to ensure sufficient contrast against a background
    def adjust_for_contrast(background, target_ratio = 4.5)
      background = Unmagic::Color.parse(background) if background.is_a?(String)
      return self unless background

      current_ratio = contrast_ratio(background)
      return self if current_ratio >= target_ratio

      # Adjust based on background lightness
      if background.light?
        darken(0.3)
      else
        lighten(0.3)
      end
    end

    def ==(other)
      other.is_a?(Unmagic::Color) &&
        @red == other.red &&
        @green == other.green &&
        @blue == other.blue
    end

    def to_s
      to_hex
    end
  end
end

# Load color subclasses after Color is defined
require_relative "color/rgb"
require_relative "color/hex"
require_relative "color/hsl"
