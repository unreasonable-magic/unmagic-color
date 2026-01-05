# frozen_string_literal: true

module Unmagic
  class Color
    module Console
      # Simple syntax highlighter for Ruby code snippets.
      #
      # Highlights strings, numbers, symbols, and comments
      # using ANSI color codes.
      #
      # @example Basic usage
      #   hl = Unmagic::Color::Console::Highlighter.new
      #   puts hl.highlight('color.to_rgb.to_s')
      #   puts hl.comment('# This is a comment')
      #
      # @example With custom colors
      #   hl = Unmagic::Color::Console::Highlighter.new(colors: { string: "#00FF00" })
      #   puts hl.highlight('parse("#FF0000")')
      class Highlighter
        # Default colors for syntax highlighting
        DEFAULT = {
          string: "#00FF00",
          number: "#FF00FF",
          symbol: "#FFFF00",
          comment: "#696969",
        }.freeze

        # @param mode [Symbol] ANSI color mode (:truecolor, :palette256, :palette16)
        # @param colors [Hash] Color overrides (keys: :string, :number, :symbol, :comment)
        def initialize(mode: :palette16, colors: DEFAULT)
          @mode = mode
          @colors = DEFAULT.merge(colors)
        end

        # Highlight a code snippet with syntax coloring.
        #
        # Supports multi-line input. Lines starting with # are treated as comments.
        #
        # @param code [String] Ruby code to highlight (single or multi-line)
        # @return [String] Code with ANSI color codes
        def highlight(code)
          code.lines.map { |line| highlight_line(line.chomp) }.join("\n")
        end

        private

        def highlight_line(line)
          # Don't highlight if already contains ANSI codes
          return line if line.include?("\e[")

          # Treat lines starting with # as comments
          return comment(line) if line.start_with?("#")

          # Empty lines pass through
          return line if line.empty?

          result = line

          # Protect strings first by replacing with placeholders
          strings = []
          result = result.gsub(/(".*?")/) do
            strings << Regexp.last_match(1)
            "\x00STRING#{strings.length - 1}\x00"
          end

          # Now highlight other elements (won't match inside strings)
          result = result
            .gsub(/\b(\d+\.?\d*%?)/) { colorize(Regexp.last_match(1), :number) }
            .gsub(/(:[a-z_]+|[a-z_]+:)/) { colorize(Regexp.last_match(1), :symbol) }

          # Restore and highlight strings
          strings.each_with_index do |str, i|
            result = result.gsub("\x00STRING#{i}\x00", colorize(str, :string))
          end

          result
        end

        public

        # Format text as a comment.
        #
        # @param text [String] Comment text
        # @return [String] Gray-colored text
        def comment(text)
          colorize(text, :comment)
        end

        # Colorize text with a specific color.
        #
        # @param text [String] Text to colorize
        # @param key [Symbol] Color key from the colors hash
        # @return [String] Text with ANSI color codes
        def colorize(text, key)
          color = Color.parse(@colors[key])
          "\e[#{color.to_ansi(mode: @mode)}m#{text}\e[0m"
        end

        # Format text as a clickable hyperlink.
        #
        # Uses ANSI palette16 blue with underline, plus OSC 8 hyperlink
        # sequence for iTerm2 and other modern terminals.
        #
        # @param url [String] The URL to link to
        # @param text [String] The display text (defaults to url)
        # @return [String] Styled, clickable link
        def link(url, text = url)
          # ANSI palette16 blue (34) + underline (4)
          "\e[4;34m\e]8;;#{url}\a#{text}\e]8;;\a\e[0m"
        end
      end
    end
  end
end
