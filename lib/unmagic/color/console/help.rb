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
          link = highlighter.link("https://github.com/unmagic/unmagic-color")

          code = highlighter.highlight(<<~RUBY)
            # Parse colors
            parse("#ff5733")
            rgb(255, 87, 51)
            hsl(9, 100, 60)
            oklch(0.65, 0.22, 30)
            parse("rebeccapurple")

            # Manipulate colors
            color = parse("#ff5733")
            color.lighten(0.1)
            color.darken(0.1)
            color.saturate(0.1)
            color.desaturate(0.1)
            color.rotate(30)

            # Convert between formats
            color.to_rgb
            color.to_hsl
            color.to_oklch
            color.to_hex
            color.to_css_oklch

            # Create gradients
            gradient(:linear, ["#FF0000", "#0000FF"]).rasterize(width: 10).pixels[0].map(&:to_hex)

            # Helpers
            rgb(255, 87, 51)
            hsl(9, 100, 60)
            oklch(0.65, 0.22, 30)
            parse("#ff5733")
            gradient(:linear, ["#FF0000", "#0000FF"])
            percentage(50)
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
