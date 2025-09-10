# frozen_string_literal: true

module Unmagic
  module Color
    # RGB color representation
    class RGB
      attr_reader :red, :green, :blue

      def initialize(red:, green:, blue:)
        @red = red.to_i.clamp(0, 255)
        @green = green.to_i.clamp(0, 255)
        @blue = blue.to_i.clamp(0, 255)
      end

      # Check if a string is a valid RGB color
      def self.valid?(value)
        return false unless value.is_a?(String)

        # Remove rgb() wrapper if present
        clean = value.gsub(/^rgb\s*\(\s*|\s*\)$/, "").strip

        # Split and check values
        values = clean.split(/\s*,\s*/)
        return false unless values.length == 3

        # Check if all values are valid integers 0-255
        values.all? { |v| v.match?(/\A\d+\z/) && v.to_i.between?(0, 255) }
      rescue
        false
      end

      # Parse RGB string like "rgb(255, 128, 0)" or "255, 128, 0"
      def self.parse(input)
        return nil unless input.is_a?(String)

        # Remove rgb() wrapper if present
        clean = input.gsub(/^rgb\s*\(\s*|\s*\)$/, "").strip

        # Split values
        values = clean.split(/\s*,\s*/)
        return nil unless values.length == 3

        # Check if all values are numeric (allow negative for clamping)
        return nil unless values.all? { |v| v.match?(/\A-?\d+\z/) }

        # Convert to integers (base class will clamp)
        parsed = values.map(&:to_i)

        new(red: parsed[0], green: parsed[1], blue: parsed[2])
      rescue
        nil
      end

      # Convert to RGB representation (returns self)
      def to_rgb
        self
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

        HSL.new(hue: (h * 360).round, saturation: (s * 100).round, lightness: (l * 100).round)
      end


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
        other_rgb = other.respond_to?(:to_rgb) ? other.to_rgb : other

        RGB.new(
          red: (@red * (1 - amount) + other_rgb.red * amount).round,
          green: (@green * (1 - amount) + other_rgb.green * amount).round,
          blue: (@blue * (1 - amount) + other_rgb.blue * amount).round
        )
      end

      # Lighten by blending with white
      def lighten(amount = 0.1)
        blend(RGB.new(red: 255, green: 255, blue: 255), amount)
      end

      # Darken by blending with black
      def darken(amount = 0.1)
        blend(RGB.new(red: 0, green: 0, blue: 0), amount)
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
        light? ? RGB.new(red: 0, green: 0, blue: 0) : RGB.new(red: 255, green: 255, blue: 255)
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
        other.is_a?(RGB) &&
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

