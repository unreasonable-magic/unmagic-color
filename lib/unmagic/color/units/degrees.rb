# frozen_string_literal: true

module Unmagic
  class Color
    # Unit types for color manipulation.
    module Units
      # Represents an angle in degrees (0-360°).
      #
      # Supports numeric values, degree strings, and named direction keywords.
      # Values are automatically wrapped to the 0-360 range.
      #
      # ## Supported Formats
      #
      # - Numeric: `225`, `45.5`
      # - Degree strings: `"225deg"`, `"45.5deg"`, `"-45deg"`, `"225°"`, `"45.5°"`
      # - Named directions: `"top"`, `"bottom left"`, `"north"`, `"southwest"`, etc.
      #
      # ## Named Direction Keywords
      #
      # - Cardinal: `"top"` (0°), `"right"` (90°), `"bottom"` (180°), `"left"` (270°)
      # - Diagonal: `"top right"` (45°), `"bottom right"` (135°), `"bottom left"` (225°), `"top left"` (315°)
      # - Aliases: `"north"`, `"south"`, `"east"`, `"west"`, `"northeast"`, etc.
      #
      # @example Numeric values
      #   Degrees.build(225)           #=> 225.0°
      #   Degrees.build(45.5)          #=> 45.5°
      #   Degrees.build(-45)           #=> 315.0° (wrapped)
      #
      # @example Degree strings
      #   Degrees.build("225deg")      #=> 225.0°
      #   Degrees.build("45.5deg")     #=> 45.5°
      #   Degrees.build("225°")        #=> 225.0°
      #
      # @example Named directions
      #   Degrees.build("top")         #=> 0.0°
      #   Degrees.build("bottom left") #=> 225.0°
      #   Degrees.build("north")       #=> 0.0° (alias for "top")
      #
      # @example Constants
      #   Degrees::TOP                 #=> 0.0°
      #   Degrees::BOTTOM_LEFT         #=> 225.0°
      #
      # @example String output
      #   Degrees::TOP.to_s            #=> "top"
      #   Degrees::TOP.to_css          #=> "0.0deg"
      #   Degrees.new(value: 123).to_s #=> "123.0°"
      class Degrees
        include Comparable

        # Error raised when parsing invalid degree values.
        class ParseError < Color::Error; end

        attr_reader :value, :name, :aliases

        class << self
          # All predefined degree constants
          #
          # @return [Array<Degrees>] All constant degree values
          def all
            all_by_name.values.uniq
          end

          # Find a constant by name or alias
          #
          # @param search [String] Name or alias to search for
          # @return [Degrees, nil] Matching constant or nil
          def find_by_name(search)
            normalized = search.strip.downcase
            all_by_name.fetch(normalized)
          rescue KeyError
            nil
          end

          private

          # Hash mapping all names and aliases to their constants
          #
          # @return [Hash<String, Degrees>] Name/alias to constant mapping
          def all_by_name
            @all_by_name ||= begin
              constants = [TOP, RIGHT, BOTTOM, LEFT, TOP_RIGHT, BOTTOM_RIGHT, BOTTOM_LEFT, TOP_LEFT]
              hash = {}
              constants.each do |constant|
                hash[constant.name] = constant
                constant.aliases.each { |alias_name| hash[alias_name] = constant }
              end
              hash
            end
          end

          public

          # Build a Degrees instance from various input formats.
          #
          # @param input [Numeric, String, Degrees] The angle to parse
          # @return [Degrees] Normalized degrees instance
          # @raise [ParseError] If input format is invalid
          #
          # @example From number
          #   Degrees.build(225)
          #
          # @example From degree string
          #   Degrees.build("225deg")
          #
          # @example From CSS direction
          #   Degrees.build("to left top")
          def build(input)
            case input
            when Degrees
              input
            when ::Numeric
              new(value: input)
            when ::String
              parse(input)
            else
              raise ParseError, "Expected Numeric, String, or Degrees, got #{input.class}"
            end
          end

          # Parse a degrees string.
          #
          # @param input [String] The string to parse
          # @return [Degrees] Parsed degrees instance
          # @raise [ParseError] If format is invalid
          def parse(input)
            raise ParseError, "Input must be a string" unless input.is_a?(::String)

            input = input.strip

            # Try to find a named constant first
            constant = find_by_name(input)
            return constant if constant

            # Remove "deg" or "°" suffix if present
            input = input.sub(/deg\z/i, "").sub(/°\z/, "")

            # Try parsing as number
            if input.match?(/\A-?\d+(?:\.\d+)?\z/)
              return new(value: input.to_f)
            end

            raise ParseError, "Invalid degrees format: #{input.inspect}"
          end
        end

        # Create a new Degrees instance.
        #
        # @param value [Numeric] Angle in degrees (wraps to 0-360 range)
        # @param name [String, nil] Optional name for this degree (e.g., "top", "bottom")
        # @param aliases [Array<String>] Optional aliases for this degree (e.g., ["north"])
        def initialize(value:, name: nil, aliases: [])
          @value = value.to_f % 360
          @name = name
          @aliases = aliases
        end

        # Convert to float value.
        #
        # @return [Float] Degrees value (0-360)
        def to_f
          @value
        end

        # Get the opposite direction (180 degrees away).
        #
        # @return [Degrees] Opposite degree
        def opposite
          opposite_value = (@value + 180) % 360
          self.class.all.find { |d| d.value == opposite_value } || self.class.new(value: opposite_value)
        end

        # Convert to CSS string format.
        #
        # @return [String] CSS degree string (e.g., "225.0deg")
        def to_css
          "#{@value}deg"
        end

        # Convert to string representation.
        #
        # @return [String] Canonical string format that can be parsed back
        def to_s
          @name || "#{@value}°"
        end

        # Compare two Degrees instances.
        #
        # @param other [Degrees, Numeric] Value to compare
        # @return [Integer, nil] Comparison result
        def <=>(other)
          case other
          when Degrees
            @value <=> other.value
          when ::Numeric
            @value <=> other.to_f
          end
        end

        # Check equality.
        #
        # @param other [Object] Value to compare
        # @return [Boolean] true if values are equal
        def ==(other)
          case other
          when Degrees
            @value == other.value
          when ::Numeric
            @value == other.to_f
          else
            false
          end
        end

        # Predefined degree constants
        TOP = new(value: 0, name: "top", aliases: ["north"]).freeze
        # Right direction (90°, east)
        RIGHT = new(value: 90, name: "right", aliases: ["east"]).freeze
        # Bottom direction (180°, south)
        BOTTOM = new(value: 180, name: "bottom", aliases: ["south"]).freeze
        # Left direction (270°, west)
        LEFT = new(value: 270, name: "left", aliases: ["west"]).freeze
        # Top-right diagonal direction (45°, northeast)
        TOP_RIGHT = new(value: 45, name: "top right", aliases: ["topright", "northeast", "north east"]).freeze
        # Bottom-right diagonal direction (135°, southeast)
        BOTTOM_RIGHT = new(value: 135, name: "bottom right", aliases: ["bottomright", "southeast", "south east"]).freeze
        # Bottom-left diagonal direction (225°, southwest)
        BOTTOM_LEFT = new(value: 225, name: "bottom left", aliases: ["bottomleft", "southwest", "south west"]).freeze
        # Top-left diagonal direction (315°, northwest)
        TOP_LEFT = new(value: 315, name: "top left", aliases: ["topleft", "northwest", "north west"]).freeze
      end
    end
  end
end
