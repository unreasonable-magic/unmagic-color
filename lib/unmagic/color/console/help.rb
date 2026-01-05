# frozen_string_literal: true

require_relative "highlighter"

module Unmagic
  class Color
    module Console
      # Renders the help text for the console.
      #
      # @example
      #   puts Unmagic::Color::Console::Help.new.render
      class Help
        # Render the help text with syntax highlighting.
        #
        # @return [String] The formatted help text
        def render
          link = highlighter.link("https://github.com/unreasonable-magic/unmagic-color")

          code = highlighter.highlight(<<~RUBY)
            # Parse a color (hex, rgb, hsl, oklch, ansi, css named, x11)
            parse("#ff5733")
            parse("goldenrod")

            # Manually create colors
            rgb(255, 87, 51, alpha: percentage(50))
            hsl(9, 100, 60)
            oklch(0.65, 0.22, 30)

            # Show a color card
            show("#ff5733")

            # Make a rainbow
            puts gradient(:linear, %w[red orange yellow green blue purple], direction: "to right").rasterize(width: 60).to_ansi
          RUBY

          "#{link}\n\n#{code}"
        end

        # @return [String] The rendered help text
        def to_s
          render
        end

        private

        def highlighter
          @highlighter ||= Highlighter.new
        end
      end
    end
  end
end
