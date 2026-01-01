# frozen_string_literal: true

module Unmagic
  class Color
    class RGB < Color
      # Named colors support for RGB colors.
      #
      # Provides access to standard named colors (like "red", "blue", "goldenrod")
      # and converts them to RGB color instances.
      #
      # @example Parse a named color
      #   Unmagic::Color::RGB::Named.parse("goldenrod")
      #   #=> RGB instance for #daa520
      #
      # @example Case-insensitive and whitespace-tolerant
      #   Unmagic::Color::RGB::Named.parse("Golden Rod")
      #   #=> RGB instance for #daa520
      #   Unmagic::Color::RGB::Named.parse("GOLDENROD")
      #   #=> RGB instance for #daa520
      #
      # @example Check if a name is valid
      #   Unmagic::Color::RGB::Named.valid?("goldenrod")
      #   #=> true
      #   Unmagic::Color::RGB::Named.valid?("notacolor")
      #   #=> false
      class Named
        # Error raised when a color name is not found
        class ParseError < Color::Error; end

        class << self
          # Parse a named color and return its RGB representation.
          #
          # @param name [String] The color name to parse (case-insensitive)
          # @return [RGB] The RGB color instance
          # @raise [ParseError] If the color name is not recognized
          #
          # @example
          #   Unmagic::Color::RGB::Named.parse("goldenrod")
          #   #=> RGB instance for #daa520
          def parse(name)
            normalized_name = normalize_name(name)
            hex_value = data[normalized_name]

            raise ParseError, "Unknown color name: #{name.inspect}" unless hex_value

            Hex.parse(hex_value)
          end

          # Check if a color name is valid.
          #
          # @param name [String] The color name to check
          # @return [Boolean] true if the name exists
          #
          # @example
          #   Unmagic::Color::RGB::Named.valid?("goldenrod")
          #   #=> true
          def valid?(name)
            normalized_name = normalize_name(name)
            data.key?(normalized_name)
          end

          # Get all available color names.
          #
          # @return [Array<String>] Array of all color names
          #
          # @example
          #   Unmagic::Color::RGB::Named.all.take(5)
          #   #=> ["black", "silver", "gray", "white", "maroon"]
          def all
            data.keys
          end

          private

          # Normalize a color name for lookup.
          # Converts to lowercase and removes all whitespace.
          #
          # @param name [String] The color name to normalize
          # @return [String] The normalized name
          def normalize_name(name)
            name.to_s.downcase.gsub(/\s+/, "")
          end

          # Load color data from the rgb.txt file.
          # Uses memoization to only load the file once.
          #
          # @return [Hash] Hash of color names to hex values
          def data
            @data ||= load_data
          end

          # Load and parse the rgb.txt file.
          #
          # @return [Hash] Hash of color names to hex values
          def load_data
            data_file = File.join(__dir__, "..", "..", "..", "..", "data", "rgb.txt")
            colors = {}

            File.readlines(data_file).each do |line|
              name, hex = line.strip.split("\t")
              next if name.nil? || hex.nil?

              colors[name] = hex
            end

            colors
          end
        end
      end
    end
  end
end
