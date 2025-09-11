# frozen_string_literal: true

module Unmagic
  class Color
    class HSL < Color
      class ParseError < Color::Error; end

      attr_reader :hue, :saturation, :lightness


      def initialize(hue:, saturation:, lightness:)
        @hue = Color::Hue.new(value: hue)
        @saturation = Color::Saturation.new(saturation)
        @lightness = Color::Lightness.new(lightness)
      end

      # Return unit instances directly
      def hue = @hue
      def saturation = @saturation
      def lightness = @lightness

      # Parse HSL string like "hsl(180, 50%, 50%)" or "180, 50%, 50%"
      def self.parse(input)
        raise ParseError.new("Input must be a string") unless input.is_a?(::String)

        # Remove hsl() wrapper if present
        clean = input.gsub(/^hsl\s*\(\s*|\s*\)$/, "").strip

        # Split and parse values
        parts = clean.split(/\s*,\s*/)
        unless parts.length == 3
          raise ParseError.new("Expected 3 HSL values, got #{parts.length}")
        end

        # Check if hue is numeric
        h_str = parts[0].strip
        unless h_str.match?(/\A\d+(\.\d+)?\z/)
          raise ParseError.new("Invalid hue value: #{h_str.inspect} (must be a number)")
        end

        # Check if saturation and lightness are numeric (with optional %)
        s_str = parts[1].gsub("%", "").strip
        l_str = parts[2].gsub("%", "").strip

        unless s_str.match?(/\A\d+(\.\d+)?\z/)
          raise ParseError.new("Invalid saturation value: #{parts[1].inspect} (must be a number with optional %)")
        end

        unless l_str.match?(/\A\d+(\.\d+)?\z/)
          raise ParseError.new("Invalid lightness value: #{parts[2].inspect} (must be a number with optional %)")
        end

        h = h_str.to_f
        s = s_str.to_f
        l = l_str.to_f

        # Validate ranges
        unless h >= 0 && h <= 360
          raise ParseError.new("Hue must be between 0 and 360, got #{h}")
        end

        unless s >= 0 && s <= 100
          raise ParseError.new("Saturation must be between 0 and 100, got #{s}")
        end

        unless l >= 0 && l <= 100
          raise ParseError.new("Lightness must be between 0 and 100, got #{l}")
        end

        new(hue: h, saturation: s, lightness: l)
      end

      # Factory: deterministic HSL from integer seed
      # Produces stable colors from hash function output.
      def self.derive(seed, lightness: 50, saturation_range: (40..80))
        raise ArgumentError.new("Seed must be an integer") unless seed.is_a?(Integer)

        h32 = seed & 0xFFFFFFFF # Ensure 32-bit

        # Hue: distribute evenly across the color wheel
        h = (h32 % 360).to_f

        # Saturation: map a byte into the provided range
        s = saturation_range.begin + ((h32 >> 8) & 0xFF) / 255.0 * (saturation_range.end - saturation_range.begin)

        new(hue: h, saturation: s, lightness: lightness)
      end

      def to_hsl
        self
      end

      # Convert to RGB
      def to_rgb
        rgb = hsl_to_rgb
        require_relative "rgb"
        Unmagic::Color::RGB.new(red: rgb[0], green: rgb[1], blue: rgb[2])
      end

      # Convert to OKLCH via RGB (placeholder)
      def to_oklch
        to_rgb.to_oklch
      end

      def luminance
        to_rgb.luminance
      end

      # Blend with another color
      def blend(other, amount = 0.5)
        amount = amount.to_f.clamp(0, 1)
        other_hsl = other.respond_to?(:to_hsl) ? other.to_hsl : other

        # Blend in HSL space
        new_hue = @hue.value * (1 - amount) + other_hsl.hue.value * amount
        new_saturation = @saturation.value * (1 - amount) + other_hsl.saturation.value * amount
        new_lightness = @lightness.value * (1 - amount) + other_hsl.lightness.value * amount

        Unmagic::Color::HSL.new(hue: new_hue, saturation: new_saturation, lightness: new_lightness)
      end

      # Lighten by adjusting lightness
      def lighten(amount = 0.1)
        amount = amount.to_f.clamp(0, 1)
        new_lightness = @lightness.value + (100 - @lightness.value) * amount
        Unmagic::Color::HSL.new(hue: @hue.value, saturation: @saturation.value, lightness: new_lightness)
      end

      # Darken by adjusting lightness
      def darken(amount = 0.1)
        amount = amount.to_f.clamp(0, 1)
        new_lightness = @lightness.value * (1 - amount)
        Unmagic::Color::HSL.new(hue: @hue.value, saturation: @saturation.value, lightness: new_lightness)
      end

      def ==(other)
        other.is_a?(Unmagic::Color::HSL) &&
          lightness == other.lightness &&
          saturation == other.saturation &&
          hue == other.hue
      end

      # Generate a progression of colors by applying lightness/saturation transformations
      #
      # Examples:
      #
      #   # Using arrays (convenient for predefined values)
      #   hsl.progression(steps: 7, lightness: [10, 20, 30, 40, 50, 60, 70])
      #   hsl.progression(steps: 5, lightness: [20, 40, 60]) # uses 60 for steps 4-5
      #   hsl.progression(steps: 3, lightness: [0, 50, 100], saturation: [80, 60, 40])
      #
      #   # Using procs for dynamic calculation
      #   hsl.progression(steps: 7, lightness: ->(_hsl, _i) { 0 })   # all black
      #   hsl.progression(steps: 7, lightness: ->(_hsl, _i) { 100 }) # all white
      #
      #   # Dynamic based on current lightness
      #   hsl.progression(
      #     steps: 7,
      #     lightness: ->(hsl, _i) { hsl.lightness < 50 ? 90 : 10 }
      #   )
      #
      #   # Complex progressions with step awareness
      #   hsl.progression(
      #     steps: 7,
      #     lightness: ->(hsl, i) { hsl.lightness + (i * 10) },
      #     saturation: ->(hsl, i) { i < 4 ? hsl.saturation : hsl.saturation - 5 }
      #   )
      #
      def progression(steps:, lightness:, saturation: nil)
        raise ArgumentError, "steps must be at least 1" if steps < 1
        raise ArgumentError, "lightness must be a proc or array" unless lightness.respond_to?(:call) || lightness.is_a?(Array)
        raise ArgumentError, "saturation must be a proc or array" if saturation && !saturation.respond_to?(:call) && !saturation.is_a?(Array)

        colors = []

        (0...steps).each do |i|
          # Calculate new lightness using the provided proc or array
          new_lightness = if lightness.is_a?(Array)
            # Use array value at index i, or last value if beyond array length
            lightness[i] || lightness.last
          else
            lightness.call(self, i)
          end
          new_lightness = new_lightness.to_f.clamp(0, 100)

          # Calculate new saturation using the provided proc/array or keep current
          new_saturation = if saturation
            if saturation.is_a?(Array)
              # Use array value at index i, or last value if beyond array length
              (saturation[i] || saturation.last).to_f.clamp(0, 100)
            else
              saturation.call(self, i).to_f.clamp(0, 100)
            end
          else
            @saturation.value
          end

          # Create new HSL color with computed values
          color = self.class.new(hue: @hue.value, saturation: new_saturation, lightness: new_lightness)
          colors << color
        end

        colors
      end

      def to_s
        "hsl(#{@hue.value.round}, #{@saturation}%, #{@lightness}%)"
      end

      private

      def hsl_to_rgb
        h = @hue.value / 360.0
        s = @saturation.to_ratio  # Convert percentage to 0-1
        l = @lightness.to_ratio # Convert percentage to 0-1

        if s == 0
          # Achromatic
          gray = (l * 255).round
          [ gray, gray, gray ]
        else
          q = l < 0.5 ? l * (1 + s) : l + s - l * s
          p = 2 * l - q

          r = hue_to_rgb(p, q, h + 1/3.0)
          g = hue_to_rgb(p, q, h)
          b = hue_to_rgb(p, q, h - 1/3.0)

          [ (r * 255).round, (g * 255).round, (b * 255).round ]
        end
      end

      def hue_to_rgb(p, q, t)
        t += 1 if t < 0
        t -= 1 if t > 1

        if t < 1/6.0
          p + (q - p) * 6 * t
        elsif t < 1/2.0
          q
        elsif t < 2/3.0
          p + (q - p) * (2/3.0 - t) * 6
        else
          p
        end
      end
    end
  end
end
