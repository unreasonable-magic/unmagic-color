# frozen_string_literal: true

module Unmagic
  class Color
    module Console
      # Simple syntax highlighter for Ruby code snippets.
      #
      # Highlights strings, numbers, symbols, method calls, and comments
      # using ANSI color codes.
      #
      # @example Basic usage
      #   hl = Unmagic::Color::Console::Highlighter.new
      #   puts hl.highlight('color.to_rgb.to_s')
      #   puts hl.comment('# This is a comment')
      #
      # @example With custom mode
      #   hl = Unmagic::Color::Console::Highlighter.new(mode: :palette16)
      #   puts hl.highlight('parse("#FF0000")')
      class Highlighter
        # @param mode [Symbol] ANSI color mode (:truecolor, :palette256, :palette16)
        def initialize(mode: :palette16)
          @mode = mode
        end

        # Highlight a code snippet with syntax coloring.
        #
        # @param code [String] Ruby code to highlight
        # @return [String] Code with ANSI color codes
        def highlight(code)
          # Don't highlight if already contains ANSI codes
          return code if code.include?("\e[")

          result = code

          # Protect strings first by replacing with placeholders
          strings = []
          result = result.gsub(/(".*?")/) do
            strings << Regexp.last_match(1)
            "\x00STRING#{strings.length - 1}\x00"
          end

          # Now highlight other elements (won't match inside strings)
          result = result
            .gsub(/\b(\d+\.?\d*%?)/) { colorize(Regexp.last_match(1), number_color) }
            .gsub(/(:[a-z_]+|[a-z_]+:)/) { colorize(Regexp.last_match(1), symbol_color) }
            .gsub(/(\.[a-z_]+)/) { colorize(Regexp.last_match(1), method_color) }

          # Restore and highlight strings
          strings.each_with_index do |str, i|
            result = result.gsub("\x00STRING#{i}\x00", colorize(str, string_color))
          end

          result
        end

        # Format text as a comment.
        #
        # @param text [String] Comment text
        # @return [String] Gray-colored text
        def comment(text)
          colorize(text, comment_color)
        end

        # Colorize text with a specific color.
        #
        # @param text [String] Text to colorize
        # @param color [Color] Color to use
        # @return [String] Text with ANSI color codes
        def colorize(text, color)
          "\e[#{color.to_ansi(mode: @mode)}m#{text}\e[0m"
        end

        private

        def string_color
          @string_color ||= Color.parse("green")
        end

        def number_color
          @number_color ||= Color.parse("#ff00ff")
        end

        def symbol_color
          @symbol_color ||= Color.parse("yellow")
        end

        def method_color
          @method_color ||= Color.parse("cyan")
        end

        def comment_color
          @comment_color ||= Color.parse("dimgray")
        end

        def result_color
          @result_color ||= Color.parse("gray")
        end
      end
    end
  end
end
