# frozen_string_literal: true

module Unmagic
  class Color
    # RGB color representation
    class RGB < Color
      class ParseError < Color::Error; end

      attr_reader :red, :green, :blue

      def initialize(red:, green:, blue:)
        @red = Color::Red.new(value: red)
        @green = Color::Green.new(value: green)
        @blue = Color::Blue.new(value: blue)
      end

      # Return unit instances directly
      def red = @red
      def green = @green
      def blue = @blue


      private



      public

      # Parse RGB string like "rgb(255, 128, 0)" or "255, 128, 0" or hex like "#FF8800" or "FF8800"
      def self.parse(input)
        raise ParseError.new("Input must be a string") unless input.is_a?(::String)

        input = input.strip

        # Check if it looks like a hex color (starts with # or only contains hex digits)
        if input.start_with?("#") || input.match?(/\A[0-9A-Fa-f]{3,6}\z/)
          return Hex.parse(input)
        end

        # Try to parse as RGB format
        parse_rgb_format(input)
      end

      # Factory: deterministic RGB from integer seed
      # Produces stable colors from hash function output.
      def self.derive(seed, brightness: 180, saturation: 0.7)
        raise ArgumentError.new("Seed must be an integer") unless seed.is_a?(Integer)

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

      private

      # Parse RGB format like "rgb(255, 128, 0)" or "255, 128, 0"
      def self.parse_rgb_format(input)
        # Remove rgb() wrapper if present
        clean = input.gsub(/^rgb\s*\(\s*|\s*\)$/, "").strip

        # Split values
        values = clean.split(/\s*,\s*/)
        unless values.length == 3
          raise ParseError.new("Expected 3 RGB values, got #{values.length}")
        end

        # Check if all values are numeric (allow negative for clamping)
        values.each_with_index do |v, i|
          unless v.match?(/\A-?\d+\z/)
            component = %w[red green blue][i]
            raise ParseError.new("Invalid #{component} value: #{v.inspect} (must be a number)")
          end
        end

        # Convert to integers (constructor will clamp)
        parsed = values.map(&:to_i)

        new(red: parsed[0], green: parsed[1], blue: parsed[2])
      end

      public

      # Convert to RGB representation (returns self)
      def to_rgb
        self
      end

      # Convert to hex string
      def to_hex
        "#%02x%02x%02x" % [ @red.value, @green.value, @blue.value ]
      end

      # Convert to HSL
      def to_hsl
        r = @red.value / 255.0
        g = @green.value / 255.0
        b = @blue.value / 255.0

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

      # Convert to OKLCH (placeholder - would need complex conversion)
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

      def luminance
        r = @red.value / 255.0
        g = @green.value / 255.0
        b = @blue.value / 255.0

        r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) ** 2.4
        g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) ** 2.4
        b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) ** 2.4

        0.2126 * r + 0.7152 * g + 0.0722 * b
      end

      # Blend with another color
      def blend(other, amount = 0.5)
        amount = amount.to_f.clamp(0, 1)
        other_rgb = other.respond_to?(:to_rgb) ? other.to_rgb : other

        Unmagic::Color::RGB.new(
          red: (@red.value * (1 - amount) + other_rgb.red.value * amount).round,
          green: (@green.value * (1 - amount) + other_rgb.green.value * amount).round,
          blue: (@blue.value * (1 - amount) + other_rgb.blue.value * amount).round
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


      def ==(other)
        other.is_a?(Unmagic::Color::RGB) &&
          @red == other.red &&
          @green == other.green &&
          @blue == other.blue
      end

      def to_s
        to_hex
      end
    end
  end
end
