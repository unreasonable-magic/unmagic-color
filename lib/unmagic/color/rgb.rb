# frozen_string_literal: true

module Unmagic
  class Color
    # RGB (Red, Green, Blue) color representation.
    #
    # Understanding RGB
    #
    # RGB is how your computer screen creates colors. Every color you see on a screen
    # is made by combining three lights: Red, Green, and Blue. Each light can be set
    # from 0 (off) to 255 (full brightness).
    #
    # Think of it like mixing three flashlights:
    # - Red=255, Green=0, Blue=0 → Pure red light
    # - Red=0, Green=255, Blue=0 → Pure green light
    # - Red=255, Green=255, Blue=0 → Yellow (red + green)
    # - Red=255, Green=255, Blue=255 → White (all lights on)
    # - Red=0, Green=0, Blue=0 → Black (all lights off)
    #
    # Why 0-255?
    #
    # Computers store each color component in 8 bits (one byte), which can hold
    # 256 different values (0-255). This gives us 256³ = 16,777,216 possible colors.
    #
    # Common Formats
    #
    # RGB colors can be written in different ways:
    # - Hex: #FF5733 (2 hex digits per component: FF=255, 57=87, 33=51)
    # - Short hex: #F73 (expanded to #FF7733)
    # - RGB function: rgb(255, 87, 51)
    #
    # Usage Examples
    #
    #   # Parse from different formats
    #   color = RGB.parse("#FF5733")
    #   color = RGB.parse("rgb(255, 87, 51)")
    #   color = RGB.parse("F73")
    #
    #   # Create directly
    #   color = RGB.new(red: 255, green: 87, blue: 51)
    #
    #   # Access components
    #   color.red.value    #=> 255
    #   color.green.value  #=> 87
    #   color.blue.value   #=> 51
    #
    #   # Convert to other formats
    #   color.to_hex       #=> "#ff5733"
    #   color.to_hsl       #=> HSL color
    #   color.to_oklch     #=> OKLCH color
    #
    #   # Generate deterministic colors from text
    #   RGB.derive("user@example.com".hash)  #=> Consistent color for this string
    class RGB < Color
      class ParseError < Color::Error; end

      attr_reader :red, :green, :blue

      # Create a new RGB color.
      #
      # @param red [Integer] Red component (0-255), values outside this range are clamped
      # @param green [Integer] Green component (0-255), values outside this range are clamped
      # @param blue [Integer] Blue component (0-255), values outside this range are clamped
      #
      # @example Create a red color
      #   RGB.new(red: 255, green: 0, blue: 0)
      #
      # @example Values are automatically clamped
      #   RGB.new(red: 300, green: -10, blue: 128)
      def initialize(red:, green:, blue:)
        super()
        @red = Color::Red.new(value: red)
        @green = Color::Green.new(value: green)
        @blue = Color::Blue.new(value: blue)
      end

      class << self
        # Parse an RGB color from a string.
        #
        # Accepts multiple formats:
        # - Hex with hash: "#FF8800", "#F80"
        # - Hex without hash: "FF8800", "F80"
        # - RGB function: "rgb(255, 128, 0)"
        # - Raw values: "255, 128, 0"
        #
        # @param input [String] The color string to parse
        # @return [RGB] The parsed RGB color
        # @raise [ParseError] If the input format is invalid
        #
        # @example Parse hex colors
        #   RGB.parse("#FF8800")
        #
        #   RGB.parse("F80")
        #
        # @example Parse RGB function
        #   RGB.parse("rgb(255, 128, 0)")
        def parse(input)
          raise ParseError, "Input must be a string" unless input.is_a?(::String)

          input = input.strip

          # Check if it looks like a hex color (starts with # or only contains hex digits)
          if input.start_with?("#") || input.match?(/\A[0-9A-Fa-f]{3,6}\z/)
            return Hex.parse(input)
          end

          # Try to parse as RGB format
          parse_rgb_format(input)
        end

        # Generate a deterministic RGB color from an integer seed.
        #
        # This creates consistent, visually distinct colors from hash values or IDs.
        # The same seed always produces the same color, making it useful for:
        # - User avatars (hash their email/username)
        # - Syntax highlighting (hash the token type)
        # - Data visualization (hash category names)
        #
        # @param seed [Integer] The seed value (typically from a hash function)
        # @param brightness [Integer] Target average brightness (0-255, default 180)
        # @param saturation [Float] Color intensity (0.0-1.0, default 0.7)
        # @return [RGB] A deterministic color based on the seed
        # @raise [ArgumentError] If seed is not an integer
        #
        # @example Generate color from email
        #   email = "user@example.com"
        #   RGB.derive(email.hash)
        #
        # @example Low saturation for subtle colors
        #   RGB.derive(12345, saturation: 0.3)
        #
        # @example High brightness for light colors
        #   RGB.derive(12345, brightness: 230)
        def derive(seed, brightness: 180, saturation: 0.7)
          raise ArgumentError, "Seed must be an integer" unless seed.is_a?(Integer)

          h32 = seed & 0xFFFFFFFF # Ensure 32-bit

          # Extract RGB components from different parts of the hash
          r_base = (h32 & 0xFF)
          g_base = ((h32 >> 8) & 0xFF)
          b_base = ((h32 >> 16) & 0xFF)

          # Apply brightness and saturation adjustments
          # Brightness controls the average RGB value
          # Saturation controls how much the channels differ from each other

          avg = (r_base + g_base + b_base) / 3.0

          # Adjust each channel relative to average
          r = avg + (r_base - avg) * saturation
          g = avg + (g_base - avg) * saturation
          b = avg + (b_base - avg) * saturation

          # Scale to target brightness
          scale = brightness / 127.5 # 127.5 is middle of 0-255
          r = (r * scale).clamp(0, 255).round
          g = (g * scale).clamp(0, 255).round
          b = (b * scale).clamp(0, 255).round

          new(red: r, green: g, blue: b)
        end

        # Parse RGB format like "rgb(255, 128, 0)" or "255, 128, 0"
        def parse_rgb_format(input)
          # Remove rgb() wrapper if present
          clean = input.gsub(/^rgb\s*\(\s*|\s*\)$/, "").strip

          # Split values
          values = clean.split(/\s*,\s*/)
          unless values.length == 3
            raise ParseError, "Expected 3 RGB values, got #{values.length}"
          end

          # Check if all values are numeric (allow negative for clamping)
          values.each_with_index do |v, i|
            unless v.match?(/\A-?\d+\z/)
              component = ["red", "green", "blue"][i]
              raise ParseError, "Invalid #{component} value: #{v.inspect} (must be a number)"
            end
          end

          # Convert to integers (constructor will clamp)
          parsed = values.map(&:to_i)

          new(red: parsed[0], green: parsed[1], blue: parsed[2])
        end
      end

      # Convert to RGB color space.
      #
      # Since this is already an RGB color, returns self.
      #
      # @return [RGB] self
      def to_rgb
        self
      end

      # Convert to hexadecimal color string.
      #
      # Returns a lowercase hex string with hash prefix, always 6 characters
      # (2 per component).
      #
      # @return [String] Hex color string like "#ff5733"
      #
      # @example
      #   rgb = RGB.new(red: 255, green: 87, blue: 51)
      #   rgb.to_hex
      #   # => "#ff5733"
      def to_hex
        format("#%02x%02x%02x", @red.value, @green.value, @blue.value)
      end

      # Convert to HSL color space.
      #
      # Converts this RGB color to HSL (Hue, Saturation, Lightness).
      # HSL is often more intuitive for color manipulation.
      #
      # @return [HSL] The color in HSL color space
      #
      # @example
      #   rgb = RGB.parse("#FF5733")
      #   hsl = rgb.to_hsl
      #
      #   hsl.hue.value         # => 11.0
      #   hsl.saturation.value  # => 100.0
      #   hsl.lightness.value   # => 60.0
      def to_hsl
        r = @red.value / 255.0
        g = @green.value / 255.0
        b = @blue.value / 255.0

        max = [r, g, b].max
        min = [r, g, b].min
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

      # Convert to OKLCH color space.
      #
      # Converts this RGB color to OKLCH (Lightness, Chroma, Hue).
      # Note: This is currently a simplified approximation.
      #
      # @return [OKLCH] The color in OKLCH color space
      def to_oklch
        # For now, simple approximation based on RGB -> HSL -> OKLCH
        # This is a simplified placeholder
        require_relative "oklch"
        # Convert lightness roughly from RGB luminance
        l = luminance
        # Approximate chroma from saturation and lightness
        hsl = to_hsl
        c = (hsl.saturation / 100.0) * 0.2 * (1 - (l - 0.5).abs * 2)
        h = hsl.hue
        Unmagic::Color::OKLCH.new(lightness: l, chroma: c, hue: h)
      end

      # Calculate the relative luminance.
      #
      # This is the perceived brightness of the color according to the WCAG
      # specification, accounting for how the human eye responds differently
      # to red, green, and blue light.
      #
      # @return [Float] Luminance from 0.0 (black) to 1.0 (white)
      #
      # @example Check if text will be readable
      #   bg = Unmagic::Color::RGB.parse("#336699")
      #   bg.luminance.round(2)
      #   # => 0.13
      #
      #   text_color = bg.luminance > 0.5 ? "dark" : "light"
      #   # => "light"
      def luminance
        r = @red.value / 255.0
        g = @green.value / 255.0
        b = @blue.value / 255.0

        r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055)**2.4
        g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055)**2.4
        b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055)**2.4

        0.2126 * r + 0.7152 * g + 0.0722 * b
      end

      # Blend this color with another color.
      #
      # Blends in RGB space by linearly interpolating each component.
      #
      # @param other [Color] The color to blend with (automatically converted to RGB)
      # @param amount [Float] How much of the other color to mix in (0.0-1.0)
      # @return [RGB] A new color that is a blend of the two
      #
      # @example Mix two colors equally
      #   red = RGB.parse("#FF0000")
      #   blue = RGB.parse("#0000FF")
      #   purple = red.blend(blue, 0.5)
      #   purple.to_hex  # => "#800080"
      #
      # @example Tint with 10% white
      #   base = RGB.parse("#336699")
      #   lighter = base.blend(RGB.new(red: 255, green: 255, blue: 255), 0.1)
      def blend(other, amount = 0.5)
        amount = amount.to_f.clamp(0, 1)
        other_rgb = other.respond_to?(:to_rgb) ? other.to_rgb : other

        Unmagic::Color::RGB.new(
          red: (@red.value * (1 - amount) + other_rgb.red.value * amount).round,
          green: (@green.value * (1 - amount) + other_rgb.green.value * amount).round,
          blue: (@blue.value * (1 - amount) + other_rgb.blue.value * amount).round,
        )
      end

      # Create a lighter version by blending with white.
      #
      # @param amount [Float] How much white to mix in (0.0-1.0, default 0.1)
      # @return [RGB] A lighter version of this color
      #
      # @example Make a color 20% lighter
      #   dark = RGB.parse("#003366")
      #   light = dark.lighten(0.2)
      def lighten(amount = 0.1)
        blend(Unmagic::Color::RGB.new(red: 255, green: 255, blue: 255), amount)
      end

      # Create a darker version by blending with black.
      #
      # @param amount [Float] How much black to mix in (0.0-1.0, default 0.1)
      # @return [RGB] A darker version of this color
      #
      # @example Make a color 30% darker
      #   bright = RGB.parse("#FF9966")
      #   dark = bright.darken(0.3)
      def darken(amount = 0.1)
        blend(Unmagic::Color::RGB.new(red: 0, green: 0, blue: 0), amount)
      end

      # Check if two RGB colors are equal.
      #
      # @param other [Object] The object to compare with
      # @return [Boolean] true if both colors have the same RGB values
      def ==(other)
        other.is_a?(Unmagic::Color::RGB) &&
          @red == other.red &&
          @green == other.green &&
          @blue == other.blue
      end

      # Convert to string representation.
      #
      # Returns the hex representation of the color.
      #
      # @return [String] Hex color string like "#ff5733"
      def to_s
        to_hex
      end
    end
  end
end
