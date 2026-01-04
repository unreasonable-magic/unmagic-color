# frozen_string_literal: true

module Unmagic
  class Color
    # `RGB` (Red, Green, Blue) color representation.
    #
    # ## Understanding RGB
    #
    # RGB is how your computer screen creates colors. Every color you see on a screen
    # is made by combining three lights: Red, Green, and Blue. Each light can be set
    # from `0` (off) to `255` (full brightness).
    #
    # Think of it like mixing three flashlights:
    #
    # - `Red=255, Green=0, Blue=0` → Pure red light
    # - `Red=0, Green=255, Blue=0` → Pure green light
    # - `Red=255, Green=255, Blue=0` → Yellow (red + green)
    # - `Red=255, Green=255, Blue=255` → White (all lights on)
    # - `Red=0, Green=0, Blue=0` → Black (all lights off)
    #
    # ## Why 0-255?
    #
    # Computers store each color component in 8 bits (one byte), which can hold
    # 256 different values (`0-255`). This gives us `256³ = 16,777,216` possible colors.
    #
    # ## Common Formats
    #
    # RGB colors can be written in different ways:
    #
    # - Hex: `#FF5733` (2 hex digits per component: `FF=255, 57=87, 33=51`)
    # - Short hex: `#F73` (expanded to `#FF7733`)
    # - RGB function: `rgb(255, 87, 51)`
    # - Named colors: `goldenrod`, `red`, `blue` (see {RGB::Named} for X11 color names)
    #
    # ## Usage Examples
    #
    #     # Parse from different formats
    #     color = Unmagic::Color::RGB.parse("#FF5733")
    #     color = Unmagic::Color::RGB.parse("rgb(255, 87, 51)")
    #     color = Unmagic::Color::RGB.parse("F73")
    #
    #     # Parse named colors (via RGB::Named or Color.parse)
    #     color = Unmagic::Color::RGB::Named.parse("goldenrod")
    #     color = Unmagic::Color.parse("goldenrod")  # Also works
    #
    #     # Create directly
    #     color = Unmagic::Color::RGB.new(red: 255, green: 87, blue: 51)
    #
    #     # Access components
    #     color.red.value    #=> 255
    #     color.green.value  #=> 87
    #     color.blue.value   #=> 51
    #
    #     # Convert to other formats
    #     color.to_hex       #=> "#ff5733"
    #     color.to_hsl       #=> HSL color
    #     color.to_oklch     #=> OKLCH color
    #
    #     # Generate deterministic colors from text
    #     Unmagic::Color::RGB.derive("user@example.com".hash)  #=> Consistent color for this string
    class RGB < Color
      # Error raised when parsing RGB color strings fails
      class ParseError < Color::Error; end

      attr_reader :red, :green, :blue, :alpha

      # Create a new RGB color.
      #
      # @param red [Integer] Red component (0-255), values outside this range are clamped
      # @param green [Integer] Green component (0-255), values outside this range are clamped
      # @param blue [Integer] Blue component (0-255), values outside this range are clamped
      # @param alpha [Numeric, Color::Alpha, nil] Alpha channel (0-100%), defaults to 100 (fully opaque)
      #
      # @example Create a red color
      #   RGB.new(red: 255, green: 0, blue: 0)
      #
      # @example Create a semi-transparent red
      #   RGB.new(red: 255, green: 0, blue: 0, alpha: 50)
      #
      # @example Values are automatically clamped
      #   RGB.new(red: 300, green: -10, blue: 128)
      def initialize(red:, green:, blue:, alpha: nil)
        super()
        @red = Color::Red.new(value: red)
        @green = Color::Green.new(value: green)
        @blue = Color::Blue.new(value: blue)
        @alpha = Color::Alpha.build(alpha) || Color::Alpha::DEFAULT
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

          # Check for ANSI format first (numeric with optional semicolons)
          if input.match?(/\A\d+(?:;\d+)*\z/) && ANSI.valid?(input)
            return ANSI.parse(input)
          end

          # Check if it looks like a hex color (starts with # or only contains hex digits)
          if input.start_with?("#") || input.match?(/\A[0-9A-Fa-f]{3,6}\z/)
            return Hex.parse(input)
          end

          # Try to parse as RGB format
          parse_rgb_format(input)
        end

        # Build an RGB color from an integer, string, positional values, or keyword arguments.
        #
        # @param args [Integer, String, Array<Integer>] Either an integer (0xRRGGBB), color string, or 3 component values
        # @option kwargs [Integer] :red Red component (0-255)
        # @option kwargs [Integer] :green Green component (0-255)
        # @option kwargs [Integer] :blue Blue component (0-255)
        # @return [RGB] The constructed RGB color
        #
        # @example From integer (packed RGB)
        #   RGB.build(0xDAA520)        # goldenrod
        #   RGB.build(14329120)        # same as 0xDAA520
        #
        # @example From string
        #   RGB.build("#FF8800")
        #
        # @example From positional values
        #   RGB.build(255, 128, 0)
        #
        # @example From keyword arguments
        #   RGB.build(red: 255, green: 128, blue: 0)
        def build(*args, **kwargs)
          # Handle keyword arguments
          return new(**kwargs) if kwargs.any?

          # Handle single argument
          if args.length == 1
            value = args[0]

            # Integer: extract RGB components via bit operations
            if value.is_a?(::Integer)
              return new(
                red: (value >> 16) & 0xFF,
                green: (value >> 8) & 0xFF,
                blue: value & 0xFF,
              )
            end

            # String: delegate to parse
            return parse(value) if value.is_a?(::String)

            raise ArgumentError, "Expected Integer or String, got #{value.class}"
          end

          # Handle three positional arguments (r, g, b)
          if args.length == 3
            values = args.map { |v| v.is_a?(::String) ? v.to_i : v }
            return new(red: values[0], green: values[1], blue: values[2])
          end

          raise ArgumentError, "Expected 1 or 3 arguments, got #{args.length}"
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

        # Parse RGB format like "rgb(255, 128, 0)" or "rgb(255 128 0 / 0.5)"
        #
        # Supports both legacy comma-separated format and modern space-separated
        # format with optional alpha value.
        #
        # @param input [String] RGB string to parse
        # @return [RGB] Parsed RGB color
        # @raise [ParseError] If format is invalid
        def parse_rgb_format(input)
          # Remove rgb() or rgba() wrapper if present
          clean = input.gsub(/^rgba?\s*\(\s*|\s*\)$/, "").strip

          # Check for modern format with slash (space-separated with / for alpha)
          # Example: "255 128 0 / 0.5" or "255 128 0 / 50%"
          if clean.include?("/")
            parts = clean.split("/").map(&:strip)
            raise ParseError, "Invalid format with /: expected 'R G B / alpha'" unless parts.length == 2

            rgb_values = parts[0].split(/\s+/)
            alpha_str = parts[1]

            unless rgb_values.length == 3
              raise ParseError, "Expected 3 RGB values before /, got #{rgb_values.length}"
            end

            alpha = Color::Alpha.parse(alpha_str)
            r, g, b = parse_rgb_values(rgb_values)

            return new(red: r, green: g, blue: b, alpha: alpha)
          end

          # Legacy comma-separated format (with or without alpha)
          # Example: "255, 128, 0" or "255, 128, 0, 0.5"
          values = clean.split(/\s*,\s*/)

          unless [3, 4].include?(values.length)
            raise ParseError, "Expected 3 or 4 RGB values, got #{values.length}"
          end

          r, g, b = parse_rgb_values(values[0..2])
          alpha = values.length == 4 ? Color::Alpha.parse(values[3]) : nil

          new(red: r, green: g, blue: b, alpha: alpha)
        end

        # Parse RGB component values
        #
        # @param values [Array<String>] Array of 3 RGB value strings
        # @return [Array<Integer>] Array of 3 integers (0-255)
        # @raise [ParseError] If values are invalid
        def parse_rgb_values(values)
          values.map.with_index do |v, i|
            unless v.match?(/\A-?\d+\z/)
              component = ["red", "green", "blue"][i]
              raise ParseError, "Invalid #{component} value: #{v.inspect} (must be a number)"
            end
            v.to_i
          end
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
      # (2 per component). If alpha is less than 100%, includes 8 characters
      # with alpha as the last 2 hex digits.
      #
      # @return [String] Hex color string like "#ff5733" or "#ff5733 80" with alpha
      #
      # @example Fully opaque color
      #   rgb = RGB.new(red: 255, green: 87, blue: 51)
      #   rgb.to_hex
      #   # => "#ff5733"
      #
      # @example Semi-transparent color
      #   rgb = RGB.new(red: 255, green: 87, blue: 51, alpha: 50)
      #   rgb.to_hex
      #   # => "#ff573380"
      def to_hex
        if @alpha.value < 100
          alpha_hex = (@alpha.to_ratio * 255).round.to_s(16).rjust(2, "0")
          format("#%02x%02x%02x%s", @red.value, @green.value, @blue.value, alpha_hex)
        else
          format("#%02x%02x%02x", @red.value, @green.value, @blue.value)
        end
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

        Unmagic::Color::HSL.new(
          hue: (h * 360).round,
          saturation: (s * 100).round,
          lightness: (l * 100).round,
          alpha: @alpha,
        )
      end

      # Convert to OKLCH color space.
      #
      # Converts this RGB color to OKLCH (Lightness, Chroma, Hue).
      #
      # @return [OKLCH] The color in OKLCH color space
      # @note This is currently a simplified approximation.
      def to_oklch
        # For now, simple approximation based on RGB -> HSL -> OKLCH
        # This is a simplified placeholder
        require_relative "oklch"
        # Convert lightness roughly from RGB luminance
        l = luminance
        # Approximate chroma from saturation and lightness
        hsl = to_hsl
        c = hsl.saturation.to_ratio * 0.2 * (1 - (l - 0.5).abs * 2)
        h = hsl.hue
        Unmagic::Color::OKLCH.new(lightness: l, chroma: c, hue: h, alpha: @alpha)
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
          alpha: @alpha.value * (1 - amount) + other_rgb.alpha.value * amount,
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

      # Convert to ANSI SGR color code.
      #
      # Returns an ANSI Select Graphic Rendition (SGR) parameter string for terminal output.
      # Supports multiple color modes for different terminal capabilities.
      #
      # @param layer [Symbol] Whether to generate foreground (:foreground) or background (:background) code
      # @param mode [Symbol] Color format mode:
      #   - :truecolor (default) - 24-bit RGB (38;2;R;G;B or 48;2;R;G;B)
      #   - :palette256 - 256-color palette (38;5;N or 48;5;N)
      #   - :palette16 - 16-color palette (30-37, 90-97, 40-47, 100-107)
      # @return [String] ANSI SGR code
      # @raise [ArgumentError] If layer or mode is invalid
      #
      # @example Default mode (truecolor)
      #   red = RGB.new(red: 255, green: 0, blue: 0)
      #   red.to_ansi
      #   # => "38;2;255;0;0"
      #
      # @example Background color
      #   red = RGB.new(red: 255, green: 0, blue: 0)
      #   red.to_ansi(layer: :background)
      #   # => "48;2;255;0;0"
      #
      # @example True color mode (explicit)
      #   custom = RGB.new(red: 100, green: 150, blue: 200)
      #   custom.to_ansi(mode: :truecolor)
      #   # => "38;2;100;150;200"
      #
      # @example 256-color palette mode
      #   custom = RGB.new(red: 100, green: 150, blue: 200)
      #   custom.to_ansi(mode: :palette256)
      #   # => "38;5;67"
      #
      # @example 16-color palette mode
      #   custom = RGB.new(red: 100, green: 150, blue: 200)
      #   custom.to_ansi(mode: :palette16)
      #   # => "34"
      def to_ansi(layer: :foreground, mode: :truecolor)
        raise ArgumentError, "layer must be :foreground or :background" unless [:foreground, :background].include?(layer)
        raise ArgumentError, "mode must be :truecolor, :palette256, or :palette16" unless [:truecolor, :palette256, :palette16].include?(mode)

        case mode
        when :truecolor
          to_ansi_truecolor(layer)
        when :palette256
          to_ansi_palette256(layer)
        when :palette16
          to_ansi_palette16(layer)
        end
      end

      private

      # Convert to ANSI true color format (24-bit RGB).
      #
      # @param layer [Symbol] Foreground or background layer
      # @return [String] ANSI SGR code
      def to_ansi_truecolor(layer)
        prefix = layer == :foreground ? 38 : 48
        "#{prefix};2;#{@red.value};#{@green.value};#{@blue.value}"
      end

      # Convert to ANSI 256-color palette format.
      #
      # Finds the nearest color in the 256-color palette.
      #
      # @param layer [Symbol] Foreground or background layer
      # @return [String] ANSI SGR code
      def to_ansi_palette256(layer)
        index = rgb_to_palette256
        prefix = layer == :foreground ? 38 : 48
        "#{prefix};5;#{index}"
      end

      # Convert to 16-color palette ANSI format.
      #
      # Finds the nearest of the 8 basic colors and uses bright variants.
      #
      # @param layer [Symbol] Foreground or background layer
      # @return [String] ANSI SGR code
      def to_ansi_palette16(layer)
        index = rgb_to_palette16
        prefix = layer == :foreground ? 90 : 100
        (prefix + index).to_s
      end

      # Find the nearest color in the 256-color palette.
      #
      # @return [Integer] Palette index (0-255)
      def rgb_to_palette256
        r = @red.value
        g = @green.value
        b = @blue.value

        # Check if it's grayscale (all components within small threshold)
        if (r - g).abs < 10 && (r - b).abs < 10 && (g - b).abs < 10
          # Use grayscale ramp (232-255)
          gray = (r + g + b) / 3
          if gray < 8
            return 16 # Use first RGB cube entry for very dark
          elsif gray > 238
            return 231 # Use last RGB cube entry for very light
          else
            # Map to grayscale ramp: 232 + (0-23)
            index = ((gray - 8) / 10.0).round
            return 232 + index.clamp(0, 23)
          end
        end

        # Find nearest in 6x6x6 RGB cube (16-231)
        # Each component: 0, 95, 135, 175, 215, 255 (values 0-5)
        r_index = rgb_to_cube_index(r)
        g_index = rgb_to_cube_index(g)
        b_index = rgb_to_cube_index(b)

        16 + (r_index * 36) + (g_index * 6) + b_index
      end

      # Convert RGB component to 6x6x6 cube index.
      #
      # @param value [Integer] RGB component value (0-255)
      # @return [Integer] Cube index (0-5)
      def rgb_to_cube_index(value)
        # Cube values: 0, 95, 135, 175, 215, 255
        # Thresholds: 47.5, 115, 155, 195, 235
        if value < 48
          0
        elsif value < 115
          1
        elsif value < 155
          2
        elsif value < 195
          3
        elsif value < 235
          4
        else
          5
        end
      end

      # Find the nearest color in the 16-color palette (0-7).
      #
      # @return [Integer] Color index (0-7)
      def rgb_to_palette16
        # Standard ANSI colors
        colors = [
          [0, 0, 0],       # 0: black
          [255, 0, 0],     # 1: red
          [0, 255, 0],     # 2: green
          [255, 255, 0],   # 3: yellow
          [0, 0, 255],     # 4: blue
          [255, 0, 255],   # 5: magenta
          [0, 255, 255],   # 6: cyan
          [255, 255, 255], # 7: white
        ]

        r = @red.value
        g = @green.value
        b = @blue.value

        min_distance = Float::INFINITY
        nearest_index = 0

        colors.each_with_index do |color, index|
          cr, cg, cb = color
          distance = ((r - cr)**2 + (g - cg)**2 + (b - cb)**2)
          if distance < min_distance
            min_distance = distance
            nearest_index = index
          end
        end

        nearest_index
      end

      public

      # Pretty print support with colored swatch in class name.
      #
      # Outputs standard Ruby object format with a colored block character
      # embedded in the class name area.
      #
      # @param pp [PrettyPrint] The pretty printer instance
      #
      # @example
      #   rgb = RGB.new(red: 255, green: 87, blue: 51)
      #   pp rgb
      #   # Outputs: #<Unmagic::Color::RGB[█] @red=255 @green=87 @blue=51>
      #   # (with colored █ block)
      def pretty_print(pp)
        pp.text("#<#{self.class.name}[\x1b[#{to_ansi(mode: :truecolor)}m█\x1b[0m] @red=#{@red.value} @green=#{@green.value} @blue=#{@blue.value}>")
      end
    end
  end
end
