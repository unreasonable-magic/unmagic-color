# frozen_string_literal: true

require_relative "highlighter"

module Unmagic
  class Color
    module Console
      # Renders a comprehensive "profile card" for a color.
      #
      # Displays the color's values in all color spaces (RGB, HSL, OKLCH),
      # harmony colors, and variations (shades, tints, tones).
      #
      # @example Basic usage
      #   card = Unmagic::Color::Console::Card.new("#FF5733")
      #   puts card.render
      #
      # @example With a color object
      #   color = Unmagic::Color.parse("rebeccapurple")
      #   puts Unmagic::Color::Console::Card.new(color)
      class Card
        # Width of the card in characters (excluding box borders)
        WIDTH = 72

        def initialize(color)
          @color = Color.parse(color)
          @highlighter = Highlighter.new
        end

        # Render the color profile card as a string.
        #
        # @return [String] The formatted card with ANSI color codes
        def render
          lines = []
          lines << top_border
          lines.concat(header_rows)
          lines << separator
          lines.concat(harmony_rows)
          lines << separator
          lines.concat(variation_rows)
          lines << bottom_border
          lines.join("\n")
        end

        # @return [String] The rendered card
        def to_s
          render
        end

        private

        # Box drawing characters
        def top_border
          "┌#{"─" * WIDTH}┐"
        end

        def bottom_border
          "└#{"─" * WIDTH}┘"
        end

        def separator
          "├#{"─" * WIDTH}┤"
        end

        def row(content)
          visible_length = content.gsub(/\e\[[0-9;]*m/, "").length
          padding = WIDTH - visible_length - 1
          "│ #{content}#{" " * [padding, 0].max}│"
        end

        # Generate a color swatch (colored block)
        def swatch(color, width: 2)
          "\e[#{color.to_ansi}m#{"█" * width}\e[0m"
        end

        # Generate multiple swatches for an array of colors
        def swatches(colors)
          colors.map { |c| swatch(c) }.join(" ")
        end

        # Header with text on left, color swatch on right (same alignment as variations)
        def header_rows
          rgb = @color.to_rgb
          hsl = @color.to_hsl
          oklch = @color.to_oklch

          left_width = 40  # Same as variation blocks
          swatch_width = WIDTH - left_width - 2  # -2 for space before row end and right margin

          color_block = swatch(@color, width: swatch_width)

          [
            row("#{rgb.to_hex.upcase.ljust(left_width)}#{color_block}"),
            row("#{"rgb(#{rgb.red.value}, #{rgb.green.value}, #{rgb.blue.value})".ljust(left_width)}#{color_block}"),
            row("#{"hsl(#{hsl.hue.value.round}, #{hsl.saturation.value.round}%, #{hsl.lightness.value.round}%)".ljust(left_width)}#{color_block}"),
            row("#{"oklch(#{format("%.2f", oklch.lightness)} #{format("%.2f", oklch.chroma.value)} #{oklch.hue.value.round})".ljust(left_width)}#{color_block}"),
          ]
        end

        # Calculate WCAG contrast ratio between two luminance values
        def contrast_ratio(lum1, lum2)
          lighter = [lum1, lum2].max
          darker = [lum1, lum2].min
          (lighter + 0.05) / (darker + 0.05)
        end

        # Harmony color rows
        def harmony_rows
          rows = []
          rows.concat(variation_block("Complementary", "complementary", @color.complementary))
          rows.concat(variation_block("Analogous", "analogous", @color.analogous))
          rows.concat(variation_block("Triadic", "triadic", @color.triadic))
          rows.concat(variation_block("Split Complementary", "split_complementary", @color.split_complementary))
          rows.concat(variation_block("Tetradic Square", "tetradic_square", @color.tetradic_square))
          rows.concat(variation_block("Tetradic Rectangle", "tetradic_rectangle", @color.tetradic_rectangle, last: true))
          rows
        end

        # Variation rows (shades, tints, tones, monochromatic)
        def variation_rows
          rows = []
          rows.concat(variation_block("Shades", "shades", @color.shades))
          rows.concat(variation_block("Tints", "tints", @color.tints))
          rows.concat(variation_block("Tones", "tones", @color.tones))
          rows.concat(variation_block("Monochromatic", "monochromatic", @color.monochromatic, last: true))
          rows
        end

        # Format a variation block with name, code, swatches and hex values
        def variation_block(name, method_name, colors, last: false)
          colors_array = colors.is_a?(Array) ? colors : [colors]
          hex_value = @color.to_rgb.to_hex.upcase

          # Build the code snippet (dimmed)
          code = "parse(\"#{hex_value}\").#{method_name}"
          dim_code = @highlighter.comment(code)

          # Calculate left column width for alignment (same as header)
          left_width = 40
          total_swatch_width = WIDTH - left_width - 2  # -2 for space and right margin

          # Auto-balance swatch widths based on number of colors
          swatch_width = total_swatch_width / colors_array.length
          swatch_row = colors_array.map { |c| swatch(c, width: swatch_width) }.join

          # Pad title and code to left column, swatches on right
          title_padded = name.ljust(left_width)
          code_padded = dim_code.ljust(left_width + dim_code.length - visible_length(dim_code))

          rows = [
            row("#{title_padded}#{swatch_row}"),
            row("#{code_padded}#{swatch_row}"),
          ]
          rows << row("") unless last
          rows
        end

        # Calculate visible length (excluding ANSI codes)
        def visible_length(str)
          str.gsub(/\e\[[0-9;]*m/, "").length
        end
      end
    end
  end
end
