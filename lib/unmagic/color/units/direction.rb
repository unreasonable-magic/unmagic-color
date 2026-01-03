# frozen_string_literal: true

require_relative "degrees"

module Unmagic
  class Color
    module Units
      class Degrees
        # Represents a gradient direction as a from/to tuple of Degrees.
        #
        # Direction defines a gradient's angle by specifying where it starts (from)
        # and where it ends (to). Supports CSS-style direction strings with flexible
        # parsing that infers missing components.
        #
        # ## Supported Formats
        #
        # - Full directions: `"from left to right"`, `"from bottom left to top right"`
        # - Implicit from: `"to top"` → infers `"from bottom to top"`
        # - Implicit to: `"from bottom"` → infers `"from bottom to top"`
        # - Without "from": `"left to right"` → `"from left to right"`
        # - Mixed formats: `"from 45deg to top right"`, `"from south to 90deg"`, `"from 45° to 90°"`
        # - Hash: `{ from: "north", to: "south" }`
        #
        # @example Parse direction strings
        #   Direction.parse("from left to right")
        #   Direction.parse("to top")                    # Infers from bottom
        #   Direction.parse("from bottom")               # Infers to top
        #   Direction.parse("left to right")             # Implicit "from"
        #   Direction.parse("from 45deg to 90deg")       # Numeric degrees
        #   Direction.parse("from 45° to 90°")           # With ° symbol
        #   Direction.parse("from south to top right")   # Mixed
        #
        # @example Build from various inputs
        #   Direction.build("from left to right")
        #   Direction.build(from: "north", to: "south")
        #   Direction.build(from: 45, to: 90)
        #
        # @example Direct construction
        #   direction = Direction.new(from: Degrees::LEFT, to: Degrees::RIGHT)
        #   direction.from.value  #=> 270.0
        #   direction.to.value    #=> 90.0
        #
        # @example Constants
        #   Direction::LEFT_TO_RIGHT
        #   Direction::BOTTOM_LEFT_TO_TOP_RIGHT
        #
        # @example String output
        #   Direction::LEFT_TO_RIGHT.to_s    #=> "from left to right"
        #   Direction::LEFT_TO_RIGHT.to_css  #=> "from left to right"
        class Direction
          attr_reader :from, :to

          class << self
            # All predefined direction constants
            #
            # @return [Array<Direction>] All constant directions
            def all
              all_constants
            end

            private

            # Array of all predefined direction constants
            #
            # @return [Array<Direction>] All constant directions
            def all_constants
              @all_constants ||= [
                BOTTOM_TO_TOP,
                LEFT_TO_RIGHT,
                TOP_TO_BOTTOM,
                RIGHT_TO_LEFT,
                BOTTOM_LEFT_TO_TOP_RIGHT,
                TOP_LEFT_TO_BOTTOM_RIGHT,
                TOP_RIGHT_TO_BOTTOM_LEFT,
                BOTTOM_RIGHT_TO_TOP_LEFT,
              ]
            end

            public

            # Check if a string looks like a direction keyword.
            #
            # @param input [String] The string to check
            # @return [Boolean] true if the string appears to be a direction keyword
            def matches?(input)
              return false unless input.is_a?(::String)

              normalized = input.strip.downcase

              # Check if it contains "from" or "to" keywords
              normalized.start_with?("to ") || normalized.start_with?("from ") || normalized.include?(" to ")
            end

            # Build a Direction from various input formats.
            #
            # @param input [String, Direction, Hash] Direction string, instance, or hash with :from and :to keys
            # @return [Direction] Direction instance
            def build(input)
              return input if input.is_a?(Direction)

              if input.is_a?(::Hash)
                raise Degrees::ParseError, "Hash must have :from and :to keys" unless input.key?(:from) && input.key?(:to)

                from_degree = Degrees.build(input[:from])
                to_degree = Degrees.build(input[:to])
                return new(from: from_degree, to: to_degree)
              end

              parse(input)
            end

            # Parse a direction string into a Direction instance.
            #
            # Supports mixed formats like:
            # - "from 275deg to 45deg"
            # - "from south to 90"
            # - "from north to top right"
            # - "to top" (infers from as opposite)
            # - "from bottom" (infers to as opposite)
            #
            # @param input [String] Direction string
            # @return [Direction] Parsed direction
            # @raise [Degrees::ParseError] If direction is invalid
            def parse(input)
              # Normalize: strip, downcase, and collapse whitespace
              normalized = input.strip.downcase.gsub(/\s+/, " ")

              # Remove "from " prefix if present, then split on "to "
              parts = normalized.delete_prefix("from ").split("to ", 2).map(&:strip)
              left = parts[0]
              right = parts[1]

              if left.empty? && right
                # Only right side specified: "to top"
                to_degree = Degrees.build(right)
                from_degree = to_degree.opposite
              elsif right.nil?
                # Only left side specified: "from bottom"
                from_degree = Degrees.build(left)
                to_degree = from_degree.opposite
              else
                # Both sides specified: "left to right" or "from left to right"
                from_degree = Degrees.build(left)
                to_degree = Degrees.build(right)
              end

              new(from: from_degree, to: to_degree)
            end
          end

          # Create a new Direction instance.
          #
          # @param from [Degrees] Starting degree
          # @param to [Degrees] Ending degree
          def initialize(from:, to:)
            @from = from
            @to = to
          end

          # Convert to CSS string format.
          #
          # @return [String] CSS direction string (e.g., "from left to right")
          def to_css
            from_str = @from.name || @from.to_css
            to_str = @to.name || @to.to_css
            "from #{from_str} to #{to_str}"
          end

          # Convert to string representation.
          #
          # @return [String] Canonical string format that can be parsed back
          def to_s
            from_str = @from.name || @from.to_s
            to_str = @to.name || @to.to_s
            "from #{from_str} to #{to_str}"
          end

          # Check equality.
          #
          # @param other [Object] Value to compare
          # @return [Boolean] true if from and to are equal
          def ==(other)
            other.is_a?(Direction) && @from == other.from && @to == other.to
          end

          # Predefined direction constants
          BOTTOM_TO_TOP = new(from: Degrees::BOTTOM, to: Degrees::TOP).freeze
          # Left to right direction (horizontal)
          LEFT_TO_RIGHT = new(from: Degrees::LEFT, to: Degrees::RIGHT).freeze
          # Top to bottom direction (vertical, default)
          TOP_TO_BOTTOM = new(from: Degrees::TOP, to: Degrees::BOTTOM).freeze
          # Right to left direction (horizontal)
          RIGHT_TO_LEFT = new(from: Degrees::RIGHT, to: Degrees::LEFT).freeze
          # Bottom-left to top-right diagonal direction
          BOTTOM_LEFT_TO_TOP_RIGHT = new(from: Degrees::BOTTOM_LEFT, to: Degrees::TOP_RIGHT).freeze
          # Top-left to bottom-right diagonal direction
          TOP_LEFT_TO_BOTTOM_RIGHT = new(from: Degrees::TOP_LEFT, to: Degrees::BOTTOM_RIGHT).freeze
          # Top-right to bottom-left diagonal direction
          TOP_RIGHT_TO_BOTTOM_LEFT = new(from: Degrees::TOP_RIGHT, to: Degrees::BOTTOM_LEFT).freeze
          # Bottom-right to top-left diagonal direction
          BOTTOM_RIGHT_TO_TOP_LEFT = new(from: Degrees::BOTTOM_RIGHT, to: Degrees::TOP_LEFT).freeze
        end
      end
    end
  end
end
