# frozen_string_literal: true

module Unmagic
  class Color
    # `HSL` (Hue, Saturation, Lightness) color representation.
    #
    # ## Understanding HSL
    #
    # While {RGB} describes colors as mixing light, HSL describes colors in a way that's
    # more intuitive to humans. It separates the "what color" from "how vibrant" and "how bright."
    #
    # ## The Three Components
    #
    # 1. **Hue** (`0-360°`): The actual color on the color wheel
    #    - `0°/360°` = Red
    #    - `60°` = Yellow
    #    - `120°` = Green
    #    - `180°` = Cyan
    #    - `240°` = Blue
    #    - `300°` = Magenta
    #
    #    Think of it as rotating around a circle of colors.
    #
    # 2. **Saturation** (`0-100%`): How pure/intense the color is
    #    - `0%` = Gray (no color, just brightness)
    #    - `50%` = Moderate color
    #    - `100%` = Full, vivid color
    #
    #    Think of it as "how much color" vs "how much gray."
    #
    # 3. **Lightness** (`0-100%`): How bright the color is
    #    - `0%` = Black (no light)
    #    - `50%` = Pure color
    #    - `100%` = White (full light)
    #
    #    Think of it as a dimmer switch.
    #
    # ## Why HSL is Useful
    #
    # HSL makes it easy to:
    #
    # - Create color variations (keep hue, adjust saturation/lightness)
    # - Generate color schemes (change hue by fixed amounts)
    # - Make colors lighter/darker without changing their "color-ness"
    #
    # ## Common Patterns
    #
    # - **Pastel colors**: High lightness, medium-low saturation (`70-80% L`, `30-50% S`)
    # - **Vibrant colors**: Medium lightness, high saturation (`50% L`, `80-100% S`)
    # - **Dark colors**: Low lightness, any saturation (`20-30% L`)
    # - **Muted colors**: Medium lightness and saturation (`40-60% L`, `30-50% S`)
    #
    # ## Examples
    #
    #     # Parse HSL colors
    #     color = Unmagic::Color::HSL.parse("hsl(120, 100%, 50%)")  # Pure green
    #     color = Unmagic::Color::HSL.parse("240, 50%, 75%")        # Light blue
    #
    #     # Create directly
    #     red = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
    #     pastel = Unmagic::Color::HSL.new(hue: 180, saturation: 40, lightness: 80)
    #
    #     # Access components
    #     color.hue.value         #=> 120 (degrees)
    #     color.saturation.value  #=> 100 (percent)
    #     color.lightness.value   #=> 50 (percent)
    #
    #     # Easy color variations
    #     lighter = color.lighten(0.2)    # Increase lightness
    #     muted = color.desaturate(0.3)   # Reduce saturation
    #
    #     # Generate color from text
    #     Unmagic::Color::HSL.derive("user@example.com".hash)  # Consistent color
    class HSL < Color
      # Error raised when parsing HSL color strings fails
      class ParseError < Color::Error; end

      attr_reader :hue, :saturation, :lightness

      # Create a new HSL color.
      #
      # @param hue [Numeric] Hue in degrees (0-360), wraps around if outside range
      # @param saturation [Numeric] Saturation percentage (0-100), clamped to range
      # @param lightness [Numeric] Lightness percentage (0-100), clamped to range
      #
      # @example Create a pure red
      #   HSL.new(hue: 0, saturation: 100, lightness: 50)
      #
      # @example Create a pastel blue
      #   HSL.new(hue: 240, saturation: 40, lightness: 80)
      def initialize(hue:, saturation:, lightness:)
        super()
        @hue = Color::Hue.new(value: hue)
        @saturation = Color::Saturation.new(saturation)
        @lightness = Color::Lightness.new(lightness)
      end

      class << self
        # Parse an HSL color from a string.
        #
        # Accepts formats:
        # - CSS format: "hsl(120, 100%, 50%)"
        # - Raw values: "120, 100%, 50%" or "120, 100, 50"
        # - Percentages optional for saturation and lightness
        #
        # @param input [String] The HSL color string to parse
        # @return [HSL] The parsed HSL color
        # @raise [ParseError] If the input format is invalid or values are out of range
        #
        # @example Parse CSS format
        #   HSL.parse("hsl(120, 100%, 50%)")
        #
        # @example Parse without function wrapper
        #   HSL.parse("240, 50%, 75%")
        def parse(input)
          raise ParseError, "Input must be a string" unless input.is_a?(::String)

          # Remove hsl() wrapper if present
          clean = input.gsub(/^hsl\s*\(\s*|\s*\)$/, "").strip

          # Split and parse values
          parts = clean.split(/\s*,\s*/)
          unless parts.length == 3
            raise ParseError, "Expected 3 HSL values, got #{parts.length}"
          end

          # Check if hue is numeric
          h_str = parts[0].strip
          unless h_str.match?(/\A\d+(\.\d+)?\z/)
            raise ParseError, "Invalid hue value: #{h_str.inspect} (must be a number)"
          end

          # Check if saturation and lightness are numeric (with optional %)
          s_str = parts[1].gsub("%", "").strip
          l_str = parts[2].gsub("%", "").strip

          unless s_str.match?(/\A\d+(\.\d+)?\z/)
            raise ParseError, "Invalid saturation value: #{parts[1].inspect} (must be a number with optional %)"
          end

          unless l_str.match?(/\A\d+(\.\d+)?\z/)
            raise ParseError, "Invalid lightness value: #{parts[2].inspect} (must be a number with optional %)"
          end

          h = h_str.to_f
          s = s_str.to_f
          l = l_str.to_f

          # Validate ranges
          if h < 0 || h > 360
            raise ParseError, "Hue must be between 0 and 360, got #{h}"
          end

          if s < 0 || s > 100
            raise ParseError, "Saturation must be between 0 and 100, got #{s}"
          end

          if l < 0 || l > 100
            raise ParseError, "Lightness must be between 0 and 100, got #{l}"
          end

          new(hue: h, saturation: s, lightness: l)
        end

        # Generate a deterministic HSL color from an integer seed.
        #
        # Creates visually distinct, consistent colors from hash values. Particularly
        # useful because HSL naturally spreads colors evenly around the color wheel.
        #
        # @param seed [Integer] The seed value (typically from a hash function)
        # @param lightness [Numeric] Fixed lightness percentage (0-100, default 50)
        # @param saturation_range [Range] Range for saturation variation (default 40..80)
        # @return [HSL] A deterministic color based on the seed
        # @raise [ArgumentError] If seed is not an integer
        #
        # @example Generate user avatar color
        #   user_color = HSL.derive("alice@example.com".hash)
        #
        # @example Generate lighter colors
        #   HSL.derive(12345, lightness: 70)
        #
        # @example Generate muted colors
        #   HSL.derive(12345, saturation_range: (20..40))
        def derive(seed, lightness: 50, saturation_range: (40..80))
          raise ArgumentError, "Seed must be an integer" unless seed.is_a?(Integer)

          h32 = seed & 0xFFFFFFFF # Ensure 32-bit

          # Hue: distribute evenly across the color wheel
          h = (h32 % 360).to_f

          # Saturation: map a byte into the provided range
          s = saturation_range.begin + ((h32 >> 8) & 0xFF) / 255.0 * (saturation_range.end - saturation_range.begin)

          new(hue: h, saturation: s, lightness: lightness)
        end
      end

      # Convert to HSL color space.
      #
      # Since this is already an HSL color, returns self.
      #
      # @return [HSL] self
      def to_hsl
        self
      end

      # Convert to RGB color space.
      #
      # @return [RGB] The color in RGB color space
      def to_rgb
        rgb = hsl_to_rgb
        require_relative "rgb"
        Unmagic::Color::RGB.new(red: rgb[0], green: rgb[1], blue: rgb[2])
      end

      # Convert to OKLCH color space.
      #
      # Converts via RGB as an intermediate step.
      #
      # @return [OKLCH] The color in OKLCH color space
      def to_oklch
        to_rgb.to_oklch
      end

      # Calculate the relative luminance.
      #
      # Converts to RGB first, then calculates luminance.
      #
      # @return [Float] Luminance from 0.0 (black) to 1.0 (white)
      def luminance
        to_rgb.luminance
      end

      # Blend this color with another color in HSL space.
      #
      # Blending in HSL can produce different results than RGB blending,
      # often creating more natural-looking color transitions.
      #
      # @param other [Color] The color to blend with (automatically converted to HSL)
      # @param amount [Float] How much of the other color to mix in (0.0-1.0)
      # @return [HSL] A new HSL color that is a blend of the two
      #
      # @example Create a color halfway between red and blue
      #   red = HSL.new(hue: 0, saturation: 100, lightness: 50)
      #   blue = HSL.new(hue: 240, saturation: 100, lightness: 50)
      #   purple = red.blend(blue, 0.5)
      def blend(other, amount = 0.5)
        amount = amount.to_f.clamp(0, 1)
        other_hsl = other.respond_to?(:to_hsl) ? other.to_hsl : other

        # Blend in HSL space
        new_hue = @hue.value * (1 - amount) + other_hsl.hue.value * amount
        new_saturation = @saturation.value * (1 - amount) + other_hsl.saturation.value * amount
        new_lightness = @lightness.value * (1 - amount) + other_hsl.lightness.value * amount

        Unmagic::Color::HSL.new(hue: new_hue, saturation: new_saturation, lightness: new_lightness)
      end

      # Create a lighter version by increasing lightness.
      #
      # In HSL, lightening moves the color toward white while preserving the hue.
      # The amount determines how far to move from the current lightness toward 100%.
      #
      # @param amount [Float] How much to lighten (0.0-1.0, default 0.1)
      # @return [HSL] A lighter version of this color
      #
      # @example Make a color 30% lighter
      #   dark = HSL.new(hue: 240, saturation: 80, lightness: 30)
      #   light = dark.lighten(0.3)
      def lighten(amount = 0.1)
        amount = amount.to_f.clamp(0, 1)
        new_lightness = @lightness.value + (100 - @lightness.value) * amount
        Unmagic::Color::HSL.new(hue: @hue.value, saturation: @saturation.value, lightness: new_lightness)
      end

      # Create a darker version by decreasing lightness.
      #
      # In HSL, darkening moves the color toward black while preserving the hue.
      # The amount determines how much to reduce the current lightness toward 0%.
      #
      # @param amount [Float] How much to darken (0.0-1.0, default 0.1)
      # @return [HSL] A darker version of this color
      #
      # @example Make a color 20% darker
      #   bright = HSL.new(hue: 60, saturation: 100, lightness: 70)
      #   subdued = bright.darken(0.2)
      def darken(amount = 0.1)
        amount = amount.to_f.clamp(0, 1)
        new_lightness = @lightness.value * (1 - amount)
        Unmagic::Color::HSL.new(hue: @hue.value, saturation: @saturation.value, lightness: new_lightness)
      end

      # Check if two HSL colors are equal.
      #
      # @param other [Object] The object to compare with
      # @return [Boolean] true if both colors have the same HSL values
      def ==(other)
        other.is_a?(Unmagic::Color::HSL) &&
          lightness == other.lightness &&
          saturation == other.saturation &&
          hue == other.hue
      end

      # Generate a progression of colors by varying lightness and saturation.
      #
      # This creates an array of related colors, useful for color scales in UI design
      # (like shades of blue from light to dark).
      #
      # The lightness and saturation can be provided as:
      # - Array: Specific values for each step (last value repeats if array is shorter)
      # - Proc: Dynamic calculation based on the base color and step index
      #
      # @param steps [Integer] Number of colors to generate (must be at least 1)
      # @param lightness [Array<Numeric>, Proc] Lightness values or calculation function
      # @param saturation [Array<Numeric>, Proc, nil] Optional saturation values or function
      # @return [Array<HSL>] Array of HSL colors in the progression
      # @raise [ArgumentError] If steps < 1 or lightness/saturation are invalid types
      #
      # @example Create a 5-step lightness progression
      #   base = Unmagic::Color::HSL.new(hue: 240, saturation: 80, lightness: 50)
      #   base.progression(steps: 5, lightness: [20, 35, 50, 65, 80])
      #
      # @example Dynamic lightness calculation
      #   base = Unmagic::Color::HSL.new(hue: 240, saturation: 80, lightness: 50)
      #   base.progression(steps: 7, lightness: ->(hsl, i) { 20 + (i * 12) })
      #
      # @example Vary both lightness and saturation
      #   base = Unmagic::Color::HSL.new(hue: 240, saturation: 80, lightness: 50)
      #   base.progression(steps: 5, lightness: [30, 45, 60, 75, 90], saturation: [100, 80, 60, 40, 20])
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

      # Convert to string representation.
      #
      # Returns the CSS hsl() function format.
      #
      # @return [String] HSL string like "hsl(240, 80%, 50%)"
      #
      # @example
      #   color = HSL.new(hue: 240, saturation: 80, lightness: 50)
      #   color.to_s
      #   # => "hsl(240, 80.0%, 50.0%)"
      def to_s
        "hsl(#{@hue.value.round}, #{@saturation.value}%, #{@lightness.value}%)"
      end

      # Convert to ANSI SGR color code.
      #
      # Converts to RGB first, then generates the ANSI code.
      #
      # @param layer [Symbol] Whether to generate foreground (:foreground) or background (:background) code
      # @return [String] ANSI SGR code like "31" or "38;2;255;0;0"
      #
      # @example
      #   color = HSL.new(hue: 0, saturation: 100, lightness: 50)
      #   color.to_ansi
      #   # => "31"
      def to_ansi(layer: :foreground)
        to_rgb.to_ansi(layer: layer)
      end

      # Pretty print support with colored swatch in class name.
      #
      # Outputs standard Ruby object format with a colored block character
      # embedded in the class name area.
      #
      # @param pp [PrettyPrint] The pretty printer instance
      #
      # @example
      #   hsl = HSL.new(hue: 9, saturation: 100, lightness: 60)
      #   pp hsl
      #   # Outputs: #<Unmagic::Color::HSL[█]:0x... @hue=9 @saturation=100 @lightness=60>
      #   # (with colored █ block)
      def pretty_print(pp)
        pp.text("#<#{self.class.name}[\x1b[#{to_ansi}m█\x1b[0m]:0x#{object_id.to_s(16)} @hue=#{@hue.value.round} @saturation=#{@saturation.value.round} @lightness=#{@lightness.value.round}>")
      end

      private

      def hsl_to_rgb
        h = @hue.value / 360.0
        s = @saturation.to_ratio # Convert percentage to 0-1
        l = @lightness.to_ratio # Convert percentage to 0-1

        if s == 0
          # Achromatic
          gray = (l * 255).round
          [gray, gray, gray]
        else
          q = l < 0.5 ? l * (1 + s) : l + s - l * s
          p = 2 * l - q

          r = hue_to_rgb(p, q, h + 1 / 3.0)
          g = hue_to_rgb(p, q, h)
          b = hue_to_rgb(p, q, h - 1 / 3.0)

          [(r * 255).round, (g * 255).round, (b * 255).round]
        end
      end

      def hue_to_rgb(p, q, t)
        t += 1 if t < 0
        t -= 1 if t > 1

        if t < 1 / 6.0
          p + (q - p) * 6 * t
        elsif t < 1 / 2.0
          q
        elsif t < 2 / 3.0
          p + (q - p) * (2 / 3.0 - t) * 6
        else
          p
        end
      end
    end
  end
end
