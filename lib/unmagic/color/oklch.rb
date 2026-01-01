# frozen_string_literal: true

module Unmagic
  class Color
    # OKLCH (Lightness, Chroma, Hue) color representation.
    #
    # Understanding OKLCH
    #
    # OKLCH is a modern color space designed to match how humans actually perceive colors.
    # Unlike RGB or even HSL, OKLCH ensures that colors with the same lightness value
    # *look* equally bright to our eyes, regardless of their hue.
    #
    # The Problem with RGB and HSL:
    #
    # In RGB and HSL, pure yellow and pure blue can have the same "lightness" value,
    # but yellow looks much brighter to our eyes. This makes it hard to create
    # consistent-looking color palettes.
    #
    # OKLCH solves this by being "perceptually uniform" - if you change lightness
    # by 0.1, it looks like the same amount of change whether you're working with
    # red, green, blue, or any other hue.
    #
    # The Three Components:
    #
    # 1. Lightness (0.0-1.0): How bright the color appears
    #    - 0.0 = Black
    #    - 0.5 = Medium brightness
    #    - 1.0 = White
    #    Unlike HSL, this matches *perceived* brightness consistently across all hues.
    #
    # 2. Chroma (0.0-0.5): How colorful/saturated it is
    #    - 0.0 = Gray (no color)
    #    - 0.15 = Moderate color (good for UI)
    #    - 0.3+ = Very vivid (use sparingly)
    #    Think of it like saturation, but more accurate to perception.
    #
    # 3. Hue (0-360°): The color itself (same as HSL)
    #    - 0°/360° = Red
    #    - 120° = Green
    #    - 240° = Blue
    #
    # Why Use OKLCH?
    #
    # - Creating accessible color palettes (ensure consistent contrast)
    # - Generating color scales that look evenly spaced
    # - Interpolating between colors smoothly
    # - Matching colors that "feel" equally bright
    #
    # When to Use Each Color Space:
    #
    # - RGB: When working with screens/displays directly
    # - HSL: When you need intuitive color manipulation
    # - OKLCH: When you need perceptually accurate colors (design systems, accessibility)
    #
    # Examples
    #
    #   # Parse OKLCH colors
    #   color = OKLCH.parse("oklch(0.65 0.15 240)")  # Medium blue
    #
    #   # Create directly
    #   accessible = OKLCH.new(lightness: 0.65, chroma: 0.15, hue: 240)
    #
    #   # Access components
    #   color.lightness  #=> 0.65 (ratio form)
    #   color.chroma.value  #=> 0.15
    #   color.hue.value     #=> 240
    #
    #   # Create perceptually uniform variations
    #   lighter = color.lighten(0.05)  # Looks 5% brighter
    #   less_colorful = color.desaturate(0.03)
    #
    #   # Generate consistent colors
    #   OKLCH.derive("user@example.com".hash)  # Perceptually balanced color
    class OKLCH < Color
      class ParseError < Color::Error; end

      attr_reader :chroma, :hue

      # Create a new OKLCH color.
      #
      # @param lightness [Float] Lightness as a ratio (0.0-1.0), clamped to range
      # @param chroma [Float] Chroma intensity (0.0-0.5), clamped to range
      # @param hue [Numeric] Hue in degrees (0-360), wraps around if outside range
      #
      # @example Create a medium blue
      #   OKLCH.new(lightness: 0.65, chroma: 0.15, hue: 240)
      #
      # @example Create a vibrant red
      #   OKLCH.new(lightness: 0.60, chroma: 0.25, hue: 30)
      def initialize(lightness:, chroma:, hue:)
        super()
        @lightness = Color::Lightness.new(lightness * 100) # Convert 0-1 to percentage
        @chroma = Color::Chroma.new(value: chroma)
        @hue = Color::Hue.new(value: hue)
      end

      # Get the lightness as a ratio (0.0-1.0).
      #
      # This overrides the attr_reader to return the ratio form, which is the
      # standard way to work with OKLCH lightness.
      #
      # @return [Float] Lightness from 0.0 (black) to 1.0 (white)
      def lightness = @lightness.to_ratio

      # Get the lightness as a percentage (0.0-100.0).
      #
      # Helper method for when you need the percentage form instead of ratio.
      #
      # @return [Float] Lightness from 0.0 to 100.0
      def lightness_percentage = @lightness.value

      class << self
        # Parse an OKLCH color from a string.
        #
        # Accepts formats:
        # - CSS format: "oklch(0.65 0.15 240)"
        # - Raw values: "0.65 0.15 240"
        # - Space-separated values
        #
        # @param input [String] The OKLCH color string to parse
        # @return [OKLCH] The parsed OKLCH color
        # @raise [ParseError] If the input format is invalid or values are out of range
        #
        # @example Parse CSS format
        #   OKLCH.parse("oklch(0.65 0.15 240)")
        #
        # @example Parse without function wrapper
        #   OKLCH.parse("0.58 0.12 180")
        def parse(input)
          raise ParseError, "Input must be a string" unless input.is_a?(::String)

          # Remove oklch() wrapper if present
          clean = input.gsub(/^oklch\s*\(\s*|\s*\)$/, "").strip

          # Split values
          parts = clean.split(/\s+/)
          unless parts.length == 3
            raise ParseError, "Expected 3 OKLCH values, got #{parts.length}"
          end

          # Check if all values are numeric
          parts.each_with_index do |v, i|
            unless v.match?(/\A\d+(\.\d+)?\z/)
              component = ["lightness", "chroma", "hue"][i]
              raise ParseError, "Invalid #{component} value: #{v.inspect} (must be a number)"
            end
          end

          # Convert to floats
          l = parts[0].to_f
          c = parts[1].to_f
          h = parts[2].to_f

          # Validate ranges
          if l < 0 || l > 1
            raise ParseError, "Lightness must be between 0 and 1, got #{l}"
          end

          if c < 0 || c > 0.5
            raise ParseError, "Chroma must be between 0 and 0.5, got #{c}"
          end

          if h < 0 || h >= 360
            raise ParseError, "Hue must be between 0 and 360, got #{h}"
          end

          new(lightness: l, chroma: c, hue: h)
        end

        # Generate a deterministic OKLCH color from an integer seed.
        #
        # Creates perceptually balanced, visually distinct colors. This is particularly
        # effective in OKLCH because the perceptual uniformity ensures all generated
        # colors have consistent perceived brightness and saturation.
        #
        # The hue distribution uses a golden-angle approach to spread colors evenly
        # and avoid clustering similar hues together.
        #
        # @param seed [Integer] The seed value (typically from a hash function)
        # @param lightness [Float] Fixed lightness value (0.0-1.0, default 0.58)
        # @param chroma_range [Range] Range for chroma variation (default 0.10..0.18)
        # @param hue_spread [Integer] Modulo for hue distribution (default 997)
        # @param hue_base [Float] Multiplier for hue calculation (default 137.508 - golden angle)
        # @return [OKLCH] A deterministic, perceptually balanced color
        # @raise [ArgumentError] If seed is not an integer
        #
        # @example Generate avatar color
        #   OKLCH.derive("user@example.com".hash)
        #
        # @example Generate lighter UI colors
        #   OKLCH.derive(12345, lightness: 0.75)
        #
        # @example Generate more saturated colors
        #   OKLCH.derive(12345, chroma_range: (0.15..0.25))
        def derive(seed, lightness: 0.58, chroma_range: (0.10..0.18), hue_spread: 997, hue_base: 137.508)
          raise ArgumentError, "Seed must be an integer" unless seed.is_a?(Integer)

          h32 = seed & 0xFFFFFFFF # Ensure 32-bit

          # Hue: golden-angle style distribution to avoid clusters
          h = (hue_base * (h32 % hue_spread)) % 360

          # Chroma: map a byte into a safe text-friendly range
          c = chroma_range.begin + ((h32 >> 8) & 0xFF) / 255.0 * (chroma_range.end - chroma_range.begin)

          new(lightness: lightness, chroma: c, hue: h)
        end
      end

      # Convert to OKLCH color space.
      #
      # Since this is already an OKLCH color, returns self.
      #
      # @return [OKLCH] self
      def to_oklch
        self
      end

      # Convert to RGB color space.
      #
      # Note: This is currently a simplified approximation. A proper OKLCH to sRGB
      # conversion requires more complex color science calculations.
      #
      # @return [RGB] The color in RGB color space (approximation)
      def to_rgb
        # For now, convert via approximation - would need proper OKLCH->sRGB conversion
        # This is a simplified placeholder that approximates RGB from OKLCH
        require_relative "rgb"

        # Simple approximation: use lightness and chroma to estimate RGB
        base = (@lightness.to_ratio * 255).round
        saturation = (@chroma * 255).value

        # Convert hue to RGB ratios (very simplified)
        h_rad = (@hue * Math::PI / 180).value
        r_offset = (Math.cos(h_rad) * saturation).round
        g_offset = (Math.cos(h_rad + 2 * Math::PI / 3) * saturation).round
        b_offset = (Math.cos(h_rad + 4 * Math::PI / 3) * saturation).round

        r = (base + r_offset).clamp(0, 255)
        g = (base + g_offset).clamp(0, 255)
        b = (base + b_offset).clamp(0, 255)

        Unmagic::Color::RGB.new(red: r, green: g, blue: b)
      end

      # Calculate the relative luminance.
      #
      # In OKLCH, the lightness value directly represents perceptual luminance,
      # so we can use it as-is.
      #
      # @return [Float] Luminance from 0.0 (black) to 1.0 (white)
      def luminance
        # OKLCH lightness is perceptually uniform, so we can use it directly
        @lightness.to_ratio # Return 0-1 range
      end

      # Create a lighter version by increasing lightness.
      #
      # In OKLCH, lightness changes are perceptually uniform, so adding 0.05
      # will look like the same brightness increase regardless of the hue.
      #
      # @param amount [Float] How much to increase lightness (default 0.03)
      # @return [OKLCH] A lighter version of this color
      #
      # @example Make a color perceptually 5% brighter
      #   color = OKLCH.new(lightness: 0.60, chroma: 0.15, hue: 240)
      #   lighter = color.lighten(0.05)
      def lighten(amount = 0.03)
        current_lightness = @lightness.to_ratio
        new_lightness = clamp01(current_lightness + amount)
        self.class.new(lightness: new_lightness, chroma: @chroma.value, hue: @hue.value)
      end

      # Create a darker version by decreasing lightness.
      #
      # @param amount [Float] How much to decrease lightness (default 0.03)
      # @return [OKLCH] A darker version of this color
      #
      # @example Make a color perceptually 5% darker
      #   color = OKLCH.new(lightness: 0.70, chroma: 0.15, hue: 120)
      #   darker = color.darken(0.05)
      def darken(amount = 0.03)
        current_lightness = @lightness.to_ratio
        new_lightness = clamp01(current_lightness - amount)
        self.class.new(lightness: new_lightness, chroma: @chroma.value, hue: @hue.value)
      end

      # Create a more saturated version by increasing chroma.
      #
      # @param amount [Float] How much to increase chroma (default 0.02)
      # @return [OKLCH] A more saturated version of this color
      #
      # @example Make a color more vivid
      #   muted = OKLCH.new(lightness: 0.65, chroma: 0.10, hue: 180)
      #   vivid = muted.saturate(0.05)
      def saturate(amount = 0.02)
        new_chroma = [@chroma.value + amount, 0.4].min
        self.class.new(lightness: @lightness.to_ratio, chroma: new_chroma, hue: @hue.value)
      end

      # Create a less saturated version by decreasing chroma.
      #
      # @param amount [Float] How much to decrease chroma (default 0.02)
      # @return [OKLCH] A less saturated version of this color
      #
      # @example Make a color more muted
      #   vivid = OKLCH.new(lightness: 0.65, chroma: 0.20, hue: 30)
      #   muted = vivid.desaturate(0.10)
      def desaturate(amount = 0.02)
        new_chroma = [@chroma.value - amount, 0.0].max
        self.class.new(lightness: @lightness.to_ratio, chroma: new_chroma, hue: @hue.value)
      end

      # Rotate the hue by a specified amount.
      #
      # @param amount [Numeric] Degrees to rotate the hue (default 10)
      # @return [OKLCH] A color with the hue rotated
      #
      # @example Shift to an analogous color
      #   blue = OKLCH.new(lightness: 0.65, chroma: 0.15, hue: 240)
      #   blue_green = blue.rotate(30)
      def rotate(amount = 10)
        new_hue = (@hue.value + amount) % 360
        self.class.new(lightness: @lightness.to_ratio, chroma: @chroma.value, hue: new_hue)
      end

      # Blend this color with another color in OKLCH space.
      #
      # Blending in OKLCH produces perceptually smooth color transitions. Uses
      # shortest-arc hue interpolation to avoid going the long way around the color wheel.
      #
      # @param other [Color] The color to blend with (automatically converted to OKLCH)
      # @param amount [Float] How much of the other color to mix in (0.0-1.0)
      # @return [OKLCH] A new OKLCH color that is a blend of the two
      #
      # @example Create a perceptually smooth gradient
      #   blue = OKLCH.new(lightness: 0.60, chroma: 0.15, hue: 240)
      #   red = OKLCH.new(lightness: 0.60, chroma: 0.15, hue: 30)
      #   purple = blue.blend(red, 0.5)
      def blend(other, amount = 0.5)
        amount = amount.to_f.clamp(0, 1)
        other_oklch = other.respond_to?(:to_oklch) ? other.to_oklch : other

        # Blend in OKLCH space with shortest-arc hue interpolation
        dh = (((other_oklch.hue.value - @hue.value + 540) % 360) - 180)
        new_hue = (@hue.value + dh * amount) % 360
        new_lightness = lightness + (other_oklch.lightness - lightness) * amount
        new_chroma = @chroma.value + (other_oklch.chroma.value - @chroma.value) * amount

        self.class.new(lightness: new_lightness, chroma: new_chroma, hue: new_hue)
      end

      # Convert to CSS oklch() function format.
      #
      # @return [String] CSS string like "oklch(0.6500 0.1500 240.00)"
      #
      # @example
      #   color = OKLCH.new(lightness: 0.65, chroma: 0.15, hue: 240)
      #   color.to_css_oklch
      #   # => "oklch(0.6500 0.1500 240.00)"
      def to_css_oklch
        format("oklch(%.4f %.4f %.2f)", @lightness.to_ratio, @chroma.value, @hue.value)
      end

      # Convert to CSS custom properties (variables).
      #
      # Outputs the color as CSS variables for lightness, chroma, and hue that can
      # be manipulated or mixed at runtime in CSS.
      #
      # @return [String] CSS variables like "--ul:0.6500;--uc:0.1500;--uh:240.00;"
      #
      # @example
      #   color = OKLCH.new(lightness: 0.65, chroma: 0.15, hue: 240)
      #   color.to_css_vars
      #   # => "--ul:0.6500;--uc:0.1500;--uh:240.00;"
      def to_css_vars
        format("--ul:%.4f;--uc:%.4f;--uh:%.2f;", @lightness.to_ratio, @chroma.value, @hue.value)
      end

      # Create a CSS color-mix() expression.
      #
      # Generates a CSS color-mix expression that blends this color with a background
      # color (typically a CSS variable).
      #
      # @param bg_css [String] The background color CSS (default "var(--bg)")
      # @param a_pct [Integer] Percentage of this color (default 72)
      # @param bg_pct [Integer] Percentage of background color (default 28)
      # @return [String] CSS color-mix expression
      #
      # @example Mix with background
      #   color = Unmagic::Color::OKLCH.new(lightness: 0.65, chroma: 0.15, hue: 240)
      #   color.to_css_color_mix
      #   # => "color-mix(in oklch, oklch(0.6500 0.1500 240.00) 72%, var(--bg) 28%)"
      #
      # @example Custom background and percentages
      #   color = Unmagic::Color::OKLCH.new(lightness: 0.65, chroma: 0.15, hue: 240)
      #   color.to_css_color_mix("#FFFFFF", a_pct: 50, bg_pct: 50)
      #   # => "color-mix(in oklch, oklch(0.6500 0.1500 240.00) 50%, #FFFFFF 50%)"
      def to_css_color_mix(bg_css = "var(--bg)", a_pct: 72, bg_pct: 28)
        "color-mix(in oklch, #{to_css_oklch} #{a_pct}%, #{bg_css} #{bg_pct}%)"
      end

      # Check if two OKLCH colors are equal.
      #
      # @param other [Object] The object to compare with
      # @return [Boolean] true if both colors have the same OKLCH values
      def ==(other)
        other.is_a?(Unmagic::Color::OKLCH) &&
          lightness == other.lightness &&
          chroma == other.chroma &&
          hue == other.hue
      end

      # Convert to string representation.
      #
      # Returns the CSS oklch() function format.
      #
      # @return [String] CSS string like "oklch(0.6500 0.1500 240.00)"
      def to_s
        to_css_oklch
      end

      private

      def clamp01(x)
        x.clamp(0.0, 1.0)
      end
    end
  end
end
