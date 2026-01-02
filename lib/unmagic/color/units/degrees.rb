# frozen_string_literal: true

module Unmagic
  class Color
    module Units
      # Represents an angle in degrees with CSS gradient direction keyword support.
      #
      # Provides a unified way to work with gradient directions, supporting both
      # numeric degrees and CSS direction keywords.
      #
      # ## Supported Formats
      #
      # - Numeric: `225`, `45.5`
      # - Degree strings: `"225deg"`, `"45deg"`
      # - CSS keywords: `"to top"`, `"to right"`, `"to bottom left"`, etc.
      #
      # ## Direction Keyword Mappings
      #
      # - `to top` → 0°
      # - `to right` → 90°
      # - `to bottom` → 180°
      # - `to left` → 270°
      # - `to top right` or `to right top` → 45°
      # - `to bottom right` or `to right bottom` → 135°
      # - `to bottom left` or `to left bottom` → 225°
      # - `to top left` or `to left top` → 315°
      #
      # @example Parse from different formats
      #   Degrees.build(225)
      #   #=> 225.0 degrees
      #
      #   Degrees.build("225deg")
      #   #=> 225.0 degrees
      #
      #   Degrees.build("to left bottom")
      #   #=> 225.0 degrees
      #
      #   Degrees.build("to bottom left")
      #   #=> 225.0 degrees (same as above)
      class Degrees
        include Comparable

        class ParseError < Color::Error; end

        attr_reader :value

        class << self
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

            # Handle "deg" suffix (case-insensitive)
            if input.match?(/\A-?\d+(?:\.\d+)?deg\z/i)
              value = input.gsub(/deg$/i, "").to_f
              return new(value: value)
            end

            # Handle CSS direction keywords (case-insensitive)
            if input.match?(/\Ato\s+/i)
              return parse_direction(input)
            end

            # Try parsing as plain number
            if input.match?(/\A-?\d+(?:\.\d+)?\z/)
              return new(value: input.to_f)
            end

            raise ParseError, "Invalid degrees format: #{input.inspect}"
          end

          private

          # Parse CSS direction keywords.
          #
          # @param input [String] Direction string (e.g., "to top", "to bottom left")
          # @return [Degrees] Parsed degrees
          # @raise [ParseError] If direction is invalid
          def parse_direction(input)
            # Remove "to " prefix and normalize whitespace
            direction = input.sub(/\Ato\s+/i, "").strip.downcase

            # Split into components and sort for consistent matching
            components = direction.split(/\s+/).sort

            # Map component combinations to degrees
            degrees = case components
            in ["top"]
              0
            in ["right"]
              90
            in ["bottom"]
              180
            in ["left"]
              270
            in ["right", "top"]
              45
            in ["bottom", "right"]
              135
            in ["bottom", "left"]
              225
            in ["left", "top"]
              315
            else
              raise ParseError, "Invalid direction: #{input.inspect}"
            end

            new(value: degrees)
          end
        end

        # Create a new Degrees instance.
        #
        # @param value [Numeric] Angle in degrees (wraps to 0-360 range)
        def initialize(value:)
          @value = value.to_f % 360
        end

        # Convert to float value.
        #
        # @return [Float] Degrees value (0-360)
        def to_f
          @value
        end

        # Convert to string representation.
        #
        # @return [String] Formatted as "Xdeg"
        def to_s
          "#{@value}deg"
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
      end
    end
  end
end
