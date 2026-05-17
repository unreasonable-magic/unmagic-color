# frozen_string_literal: true

module Unmagic
  class Color
    # Color harmony and variations module.
    #
    # Provides methods for generating harmonious color palettes based on
    # color theory principles. Harmony and the {#shades}/{#tints}/{#tones}
    # variations are computed in HSL color space for accurate hue-based
    # relationships; {#scale} is computed in OKLCH for perceptual uniformity.
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
      # Default lightness curve for {#scale}: 11 control points describing the
      # *shape* of the light→dark sweep (1.0 = lightest, 0.0 = darkest), sampled
      # with linear interpolation. Derived from the average of several
      # hand-tuned production color ramps.
      SCALE_LIGHTNESS_SHAPE = [
        1.0, 0.948, 0.876, 0.769, 0.622, 0.514, 0.416, 0.323, 0.234, 0.168, 0.0,
      ].freeze

      # Default chroma curve for {#scale}: 11 control points (peak normalized
      # to 1.0). Chroma rises into the mid-tones and tapers toward both ends —
      # a constant chroma reads as muddy near white and neon near black, and
      # the sRGB gamut itself narrows at the extremes.
      SCALE_CHROMA_CURVE = [
        0.055, 0.131, 0.247, 0.447, 0.727, 0.920, 1.0, 0.931, 0.767, 0.586, 0.374,
      ].freeze

      # Default lightness endpoints `[lightest, darkest]` for {#scale}.
      SCALE_LIGHTNESS_DEFAULT = [0.971, 0.270].freeze

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

      # Generate a perceptually-uniform tonal scale from this color.
      #
      # Produces an ordered sequence of colors from light to dark, computed in
      # the OKLCH color space so each step sits an even perceptual distance
      # from the last. Unlike {#shades}/{#tints} (which blend toward black or
      # white in HSL), `scale` controls lightness, chroma, and hue
      # independently and gamut-maps every result.
      #
      # The chroma curve is the important part: chroma rises into the
      # mid-tones and tapers toward both ends, because a constant chroma reads
      # as muddy near white and as neon near black, and because the sRGB gamut
      # itself narrows at the extremes.
      #
      # This is a general-purpose primitive. An 11-step scale anchored in the
      # middle happens to produce a Tailwind-style 50–950 palette, but the
      # method itself knows nothing about Tailwind.
      #
      # @param steps [Integer] Number of colors to generate (must be at least 2)
      # @param lightness [Range, Array<Numeric>, Proc, nil] OKLCH lightness
      #   control. A `Range` gives the light/dark endpoints; an `Array` gives
      #   an explicit value per step; a `Proc` is called with `(t, index)`;
      #   `nil` uses the default curve.
      # @param chroma [Symbol, Array<Numeric>, Proc] OKLCH chroma control.
      #   `:peak` (default) applies the tapered curve scaled to this color's
      #   chroma; `:flat` holds chroma constant; an `Array` or `Proc` supplies
      #   values directly.
      # @param hue_shift [Range, Numeric, Proc, nil] Hue drift in degrees
      #   across the scale. `nil` (default) keeps the hue constant.
      # @param anchor [Integer, nil] Index at which this color is placed
      #   exactly — its lightness, chroma, and hue are preserved at that step
      #   and the rest of the scale is built around it.
      # @param gamut [Symbol] `:srgb` (default) gamut-maps every result into
      #   sRGB so {RGB#to_hex} is trustworthy; `:none` returns the raw OKLCH
      #   colors, which may be wider than sRGB.
      # @return [Array<OKLCH>] `steps` colors in OKLCH, ordered light to dark
      # @raise [ArgumentError] If steps < 2, anchor is out of range, or gamut
      #   is not :srgb or :none
      #
      # @example An 11-step palette anchored on the base color
      #   base = Unmagic::Color.parse("oklch(0.62 0.21 260)")
      #   palette = base.scale(steps: 11, anchor: 5)
      #
      # @example Label an 11-step scale as Tailwind stops
      #   stops = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]
      #   tailwind = stops.zip(base.scale(steps: 11, anchor: 5)).to_h
      def scale(steps: 11, lightness: nil, chroma: :peak, hue_shift: nil, anchor: nil, gamut: :srgb)
        raise ArgumentError, "steps must be at least 2" if steps < 2
        if anchor && !(0...steps).cover?(anchor)
          raise ArgumentError, "anchor must be between 0 and #{steps - 1}"
        end
        unless [:srgb, :none].include?(gamut)
          raise ArgumentError, "gamut must be :srgb or :none"
        end

        base = to_oklch
        positions = Array.new(steps) { |i| i.fdiv(steps - 1) }

        lightnesses = scale_lightness(positions, lightness, anchor, base.lightness)
        chromas = scale_chroma(positions, chroma, anchor, base.chroma.value)
        hues = scale_hue(positions, hue_shift, base.hue.value)

        Array.new(steps) do |i|
          color = OKLCH.new(
            lightness: lightnesses[i].clamp(0.0, 1.0),
            chroma: [chromas[i], 0.0].max,
            hue: hues[i],
            alpha: base.alpha.value,
          )
          gamut == :none ? color : color.clamp_to_gamut
        end
      end

      private

      # Compute the OKLCH lightness for each step of a {#scale}.
      #
      # @return [Array<Float>] One lightness ratio (0.0-1.0) per step
      def scale_lightness(positions, lightness, anchor, base_lightness)
        case lightness
        when Array
          positions.each_index.map { |i| lightness[i] || lightness.last }
        when Proc
          positions.each_index.map { |i| lightness.call(positions[i], i) }
        else
          light, dark = if lightness.is_a?(Range)
            [lightness.begin.to_f, lightness.end.to_f]
          else
            SCALE_LIGHTNESS_DEFAULT
          end
          shape = positions.map { |t| interpolate_curve(SCALE_LIGHTNESS_SHAPE, t) }
          return shape.map { |s| dark + (light - dark) * s } unless anchor

          warp_lightness_to_anchor(shape, shape[anchor], base_lightness, light, dark)
        end
      end

      # Warp the lightness shape so it passes exactly through the base color's
      # lightness at the anchor, keeping the curve monotonic and pinned to the
      # light/dark endpoints. The light and dark halves are scaled separately.
      #
      # @return [Array<Float>] One lightness ratio per step
      def warp_lightness_to_anchor(shape, anchor_shape, base_lightness, light, dark)
        shape.map do |s|
          if s >= anchor_shape
            next base_lightness if anchor_shape >= 1.0

            base_lightness + (light - base_lightness) * (s - anchor_shape) / (1.0 - anchor_shape)
          else
            next base_lightness unless anchor_shape.positive?

            dark + (base_lightness - dark) * s / anchor_shape
          end
        end
      end

      # Compute the OKLCH chroma for each step of a {#scale}.
      #
      # @return [Array<Float>] One chroma value per step
      def scale_chroma(positions, chroma, anchor, base_chroma)
        case chroma
        when :flat
          positions.map { base_chroma }
        when Array
          positions.each_index.map { |i| chroma[i] || chroma.last }
        when Proc
          positions.each_index.map { |i| chroma.call(positions[i], i) }
        when :peak, nil
          curve = positions.map { |t| interpolate_curve(SCALE_CHROMA_CURVE, t) }
          reference = anchor ? curve[anchor] : curve.max
          factor = reference.zero? ? 0.0 : base_chroma / reference
          curve.map { |c| c * factor }
        else
          raise ArgumentError, "chroma must be :peak, :flat, an Array, or a Proc"
        end
      end

      # Compute the OKLCH hue for each step of a {#scale}.
      #
      # @return [Array<Float>] One hue value (degrees) per step
      def scale_hue(positions, hue_shift, base_hue)
        case hue_shift
        when nil
          positions.map { base_hue }
        when Range
          from = hue_shift.begin.to_f
          to = hue_shift.end.to_f
          positions.map { |t| base_hue + from + (to - from) * t }
        when Numeric
          positions.map { |t| base_hue + (hue_shift * t) }
        when Proc
          positions.each_index.map { |i| base_hue + hue_shift.call(positions[i], i) }
        else
          raise ArgumentError, "hue_shift must be nil, a Range, Numeric, or a Proc"
        end
      end

      # Sample an evenly-spaced control-point array at position `t` (0.0-1.0),
      # linearly interpolating between the two nearest points.
      #
      # @return [Float] The interpolated value
      def interpolate_curve(control, t)
        t = t.clamp(0.0, 1.0)
        x = t * (control.length - 1)
        low = x.floor
        high = [low + 1, control.length - 1].min
        control[low] + (control[high] - control[low]) * (x - low)
      end

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
