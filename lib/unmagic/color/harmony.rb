# frozen_string_literal: true

module Unmagic
  class Color
    # Color harmony and variations module.
    #
    # Provides methods for generating harmonious color palettes based on
    # color theory principles. All calculations are performed in HSL color space
    # for accurate hue-based relationships.
    #
    # Included in the base Color class, making these methods available to
    # RGB, HSL, and OKLCH color spaces via inheritance.
    #
    # ## Color Harmonies
    #
    # Color harmonies are combinations of colors that are aesthetically pleasing
    # based on their positions on the color wheel:
    #
    # - **Complementary**: Colors opposite on the wheel (180° apart)
    # - **Analogous**: Colors adjacent on the wheel (typically 30° apart)
    # - **Triadic**: Three colors evenly spaced (120° apart)
    # - **Split-complementary**: Base color plus two colors adjacent to its complement
    # - **Tetradic**: Four colors forming a rectangle or square on the wheel
    #
    # ## Color Variations
    #
    # Create related colors by adjusting lightness or saturation:
    #
    # - **Shades**: Darker versions (reducing lightness)
    # - **Tints**: Lighter versions (increasing lightness)
    # - **Tones**: Less saturated versions (reducing saturation)
    #
    # @example Basic harmony usage
    #   red = Unmagic::Color.parse("#FF0000")
    #   red.complementary          # => #<RGB #00ffff>
    #   red.triadic                # => [#<RGB ...>, #<RGB ...>]
    #
    # @example Color variations
    #   blue = Unmagic::Color.parse("#0000FF")
    #   blue.shades(steps: 3)      # => [darker1, darker2, darker3]
    #   blue.tints(steps: 3)       # => [lighter1, lighter2, lighter3]
    module Harmony
      # Returns the complementary color (180° opposite on the color wheel).
      #
      # Complementary colors create high contrast and visual tension.
      # They're effective for creating emphasis and drawing attention.
      #
      # @return [RGB, HSL, OKLCH] The complementary color (same type as self)
      #
      # @example
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.complementary
      #   # => #<RGB #00ffff> (cyan)
      def complementary
        rotate_hue(180)
      end

      # Returns two analogous colors (adjacent on the color wheel).
      #
      # Analogous colors create harmonious, cohesive designs. They're often
      # found in nature and produce a calm, comfortable feel.
      #
      # @param angle [Numeric] Degrees of separation from the base color (default: 30)
      # @return [Array<RGB, HSL, OKLCH>] Two colors [-angle, +angle] from the base
      #
      # @example Default 30° separation
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.analogous
      #   # => [#<RGB ...>, #<RGB ...>] (red-violet, red-orange)
      #
      # @example Custom 15° separation
      #   red.analogous(angle: 15)
      def analogous(angle: 30)
        [rotate_hue(-angle), rotate_hue(angle)]
      end

      # Returns two triadic colors (evenly spaced 120° on the color wheel).
      #
      # Triadic colors offer strong visual contrast while retaining harmony.
      # They tend to be vibrant even when using pale or unsaturated versions.
      #
      # @return [Array<RGB, HSL, OKLCH>] Two colors at +120° and +240°
      #
      # @example
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.triadic
      #   # => [#<RGB ...>, #<RGB ...>] (green-ish, blue-ish)
      def triadic
        [rotate_hue(120), rotate_hue(240)]
      end

      # Returns two split-complementary colors.
      #
      # Split-complementary uses the two colors adjacent to the complement,
      # providing high contrast with less tension than pure complementary.
      #
      # @param angle [Numeric] Degrees from the complement (default: 30)
      # @return [Array<RGB, HSL, OKLCH>] Two colors at (180-angle)° and (180+angle)°
      #
      # @example
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.split_complementary
      #   # => [#<RGB ...>, #<RGB ...>] (cyan-blue, cyan-green)
      def split_complementary(angle: 30)
        [rotate_hue(180 - angle), rotate_hue(180 + angle)]
      end

      # Returns three tetradic colors forming a square on the color wheel.
      #
      # Square tetradic uses four colors evenly spaced (90° apart).
      # This creates a rich, bold color scheme with equal visual weight.
      #
      # @return [Array<RGB, HSL, OKLCH>] Three colors at +90°, +180°, +270°
      #
      # @example
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.tetradic_square
      #   # => [#<RGB ...>, #<RGB ...>, #<RGB ...>]
      def tetradic_square
        [rotate_hue(90), rotate_hue(180), rotate_hue(270)]
      end

      # Returns three tetradic colors forming a rectangle on the color wheel.
      #
      # Rectangular tetradic uses two complementary pairs with configurable
      # spacing. This provides flexibility between harmony and contrast.
      #
      # @param angle [Numeric] Degrees between first pair (default: 60)
      # @return [Array<RGB, HSL, OKLCH>] Three colors at +angle°, +180°, +(180+angle)°
      #
      # @example
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.tetradic_rectangle(angle: 60)
      def tetradic_rectangle(angle: 60)
        [rotate_hue(angle), rotate_hue(180), rotate_hue(180 + angle)]
      end

      # Returns an array of colors with varying lightness (same hue).
      #
      # Creates a monochromatic palette by generating colors across a
      # lightness range while preserving hue and saturation.
      #
      # @param steps [Integer] Number of colors to generate (default: 5)
      # @return [Array<RGB, HSL, OKLCH>] Colors with lightness from 15% to 85%
      #
      # @example
      #   blue = Unmagic::Color.parse("#0000FF")
      #   blue.monochromatic(steps: 5)
      #   # => [very dark blue, dark blue, medium blue, light blue, very light blue]
      def monochromatic(steps: 5)
        raise ArgumentError, "steps must be at least 1" if steps < 1

        hsl = to_hsl
        min_lightness = 15.0
        max_lightness = 85.0
        step_size = (max_lightness - min_lightness) / (steps - 1).to_f

        (0...steps).map do |i|
          lightness = min_lightness + (i * step_size)
          result = HSL.new(
            hue: hsl.hue.value,
            saturation: hsl.saturation.value,
            lightness: lightness,
            alpha: hsl.alpha.value,
          )
          convert_harmony_result(result)
        end
      end

      # Returns an array of progressively darker colors (shades).
      #
      # Shades are created by reducing lightness, simulating the effect
      # of adding black to the original color.
      #
      # @param steps [Integer] Number of shades to generate (default: 5)
      # @param amount [Float] Total amount of darkening 0.0-1.0 (default: 0.5)
      # @return [Array<RGB, HSL, OKLCH>] Progressively darker colors
      #
      # @example
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.shades(steps: 3)
      #   # => [slightly darker red, darker red, darkest red]
      def shades(steps: 5, amount: 0.5)
        raise ArgumentError, "steps must be at least 1" if steps < 1

        hsl = to_hsl
        step_amount = amount / steps.to_f

        (1..steps).map do |i|
          new_lightness = hsl.lightness.value * (1 - (step_amount * i))
          result = HSL.new(
            hue: hsl.hue.value,
            saturation: hsl.saturation.value,
            lightness: new_lightness.clamp(0, 100),
            alpha: hsl.alpha.value,
          )
          convert_harmony_result(result)
        end
      end

      # Returns an array of progressively lighter colors (tints).
      #
      # Tints are created by increasing lightness, simulating the effect
      # of adding white to the original color.
      #
      # @param steps [Integer] Number of tints to generate (default: 5)
      # @param amount [Float] Total amount of lightening 0.0-1.0 (default: 0.5)
      # @return [Array<RGB, HSL, OKLCH>] Progressively lighter colors
      #
      # @example
      #   blue = Unmagic::Color.parse("#0000FF")
      #   blue.tints(steps: 3)
      #   # => [slightly lighter blue, lighter blue, lightest blue]
      def tints(steps: 5, amount: 0.5)
        raise ArgumentError, "steps must be at least 1" if steps < 1

        hsl = to_hsl
        step_amount = amount / steps.to_f

        (1..steps).map do |i|
          new_lightness = hsl.lightness.value + (100 - hsl.lightness.value) * (step_amount * i)
          result = HSL.new(
            hue: hsl.hue.value,
            saturation: hsl.saturation.value,
            lightness: new_lightness.clamp(0, 100),
            alpha: hsl.alpha.value,
          )
          convert_harmony_result(result)
        end
      end

      # Returns an array of progressively desaturated colors (tones).
      #
      # Tones are created by reducing saturation, simulating the effect
      # of adding gray to the original color.
      #
      # @param steps [Integer] Number of tones to generate (default: 5)
      # @param amount [Float] Total amount of desaturation 0.0-1.0 (default: 0.5)
      # @return [Array<RGB, HSL, OKLCH>] Progressively less saturated colors
      #
      # @example
      #   red = Unmagic::Color.parse("#FF0000")
      #   red.tones(steps: 3)
      #   # => [slightly muted red, more muted red, grayish red]
      def tones(steps: 5, amount: 0.5)
        raise ArgumentError, "steps must be at least 1" if steps < 1

        hsl = to_hsl
        step_amount = amount / steps.to_f

        (1..steps).map do |i|
          new_saturation = hsl.saturation.value * (1 - (step_amount * i))
          result = HSL.new(
            hue: hsl.hue.value,
            saturation: new_saturation.clamp(0, 100),
            lightness: hsl.lightness.value,
            alpha: hsl.alpha.value,
          )
          convert_harmony_result(result)
        end
      end

      private

      # Rotate the hue by the specified degrees and return a new color.
      #
      # @param degrees [Numeric] Degrees to rotate (positive = clockwise)
      # @return [RGB, HSL, OKLCH] New color with rotated hue (same type as self)
      def rotate_hue(degrees)
        hsl = to_hsl
        result = HSL.new(
          hue: hsl.hue.value + degrees,
          saturation: hsl.saturation.value,
          lightness: hsl.lightness.value,
          alpha: hsl.alpha.value,
        )
        convert_harmony_result(result)
      end

      # Convert an HSL result back to the original color space.
      #
      # @param hsl_color [HSL] The HSL color to convert
      # @return [RGB, HSL, OKLCH] Color in the same space as self
      def convert_harmony_result(hsl_color)
        case self
        when RGB then hsl_color.to_rgb
        when OKLCH then hsl_color.to_oklch
        else hsl_color
        end
      end
    end
  end
end
