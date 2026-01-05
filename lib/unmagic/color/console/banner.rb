# frozen_string_literal: true

module Unmagic
  class Color
    module Console
      # Renders the colorized ASCII art banner for the console.
      #
      # @example
      #   puts Unmagic::Color::Console::Banner.new.render
      class Banner
        # ASCII art lines for the banner
        LINES = [
          "                                                              ▄▄",
          "                                  ▀▀                          ██",
          " ██ ██ ████▄ ███▄███▄  ▀▀█▄ ▄████ ██  ▄████       ▄████ ▄███▄ ██ ▄███▄ ████▄",
          " ██ ██ ██ ██ ██ ██ ██ ▄█▀██ ██ ██ ██  ██    ▀▀▀▀▀ ██    ██ ██ ██ ██ ██ ██ ▀▀",
          " ▀██▀█ ██ ██ ██ ██ ██ ▀█▄██ ▀████ ██▄ ▀████       ▀████ ▀███▀ ██ ▀███▀ ██",
          "                               ██",
          "                             ▀▀▀",
        ].freeze

        # Gradient colors for the banner (magenta -> cyan -> green -> yellow -> red)
        COLORS = ["#ff00ff", "#00ffff", "#00ff00", "#ffff00", "#ff0000"].freeze

        # Render the banner with gradient coloring.
        #
        # @return [String] The colorized banner
        def render
          gradient = Gradient.linear(COLORS, direction: "left to right")

          height = LINES.length
          width = LINES.map(&:length).max

          bitmap = gradient.rasterize(width: width, height: height)

          LINES.each_with_index.map do |line, y|
            line.chars.each_with_index.map do |char, x|
              if char.strip.empty?
                char
              else
                color = bitmap.pixels[y][x]
                "\e[#{color.to_ansi}m#{char}\e[0m"
              end
            end.join
          end.join("\n")
        end

        # @return [String] The rendered banner
        def to_s
          render
        end
      end
    end
  end
end
