# frozen_string_literal: true

module Unmagic
  # Utility classes for color manipulation
  module Util
    # Represents a percentage value with validation and formatting capabilities.
    # Handles both direct percentage values and ratio calculations.
    #
    # @example Direct percentage value
    #   percentage = Percentage.new(75.5)
    #   percentage.to_s
    #   #=> "75.5%"
    #   percentage.value
    #   #=> 75.5
    #
    # @example Calculated from ratio
    #   percentage = Percentage.new(50, 100)
    #   percentage.to_s
    #   #=> "50.0%"
    #
    # @example Progress tracking
    #   percentage = Percentage.new(current_item, total_items)
    #   percentage.to_s
    #   #=> "25.0%"
    class Percentage
      include Comparable

      attr_reader :value

      # Create a new percentage
      #
      # @param args [Array<Numeric>] Either a single percentage value (0-100) or numerator and denominator
      def initialize(*args)
        case args.length
        when 1
          @value = args[0].to_f
        when 2
          numerator, denominator = args
          @value = if denominator.to_f.zero?
            0.0
          else
            (numerator.to_f / denominator.to_f * 100.0)
          end
        else
          raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 1..2)"
        end

        # Clamp to valid percentage range
        @value = @value.clamp(0.0, 100.0)
      end

      class << self
        # Parse a percentage from string format.
        #
        # Handles multiple formats:
        # - Explicit percentage: "50%" → 50.0
        # - Fraction notation: "10/100" → 10.0
        # - Bare decimal ≤ 1.0: "0.5" → 50.0 (treated as ratio)
        # - Bare decimal > 1.0: "75" → 75.0 (treated as literal percentage)
        #
        # @param input [String] The string to parse
        # @return [Percentage] The parsed percentage
        # @raise [ArgumentError] If input is not a string or format is invalid
        #
        # @example Parse explicit percentage
        #   Percentage.parse("23.5%")
        #   #=> Percentage with value 23.5
        #
        # @example Parse ratio
        #   Percentage.parse("0.5")
        #   #=> Percentage with value 50.0
        #
        # @example Parse fraction
        #   Percentage.parse("1/4")
        #   #=> Percentage with value 25.0
        def parse(input)
          raise ArgumentError, "Input must be a string" unless input.is_a?(::String)

          input = input.strip

          # Handle explicit percentage format
          if input.end_with?("%")
            value = input.chomp("%").to_f
            return new(value)
          end

          # Handle fraction notation
          if input.include?("/")
            parts = input.split("/").map(&:strip)
            raise ArgumentError, "Invalid fraction format" unless parts.length == 2

            numerator = parts[0].to_f
            denominator = parts[1].to_f
            return new(numerator, denominator)
          end

          # Handle bare numeric values
          value = input.to_f

          # If value is <= 1.0, treat as ratio (multiply by 100)
          # If value is > 1.0, treat as literal percentage value
          if value <= 1.0
            new(value * 100)
          else
            new(value)
          end
        end
      end

      # Format as percentage string with configurable decimal places
      #
      # @param decimal_places [Integer] Number of decimal places to display
      # @return [String] Formatted percentage string
      def to_s(decimal_places: 1)
        "#{@value.round(decimal_places)}%"
      end

      # Get the raw percentage value (0.0 to 100.0)
      def to_f
        @value
      end

      # Get the percentage as a ratio (0.0 to 1.0)
      def to_ratio
        @value / 100.0
      end

      # Comparison operator for Comparable
      #
      # @param other [Percentage, Numeric] Value to compare with
      # @return [Integer, nil] -1, 0, 1, or nil
      def <=>(other)
        case other
        when Percentage
          @value <=> other.value
        when Numeric
          @value <=> other.to_f
        end
      end

      # Equality comparison
      #
      # @param other [Object] Value to compare with
      # @return [Boolean] true if values are equal
      def ==(other)
        case other
        when Percentage
          @value == other.value
        when Numeric
          @value == other.to_f
        else
          false
        end
      end

      # Add percentages (clamped to 100%)
      #
      # @param other [Percentage, Numeric] Value to add
      # @return [Percentage] New percentage with sum of values
      def +(other)
        case other
        when Percentage
          Percentage.new([value + other.value, 100.0].min)
        when Numeric
          Percentage.new([value + other.to_f, 100.0].min)
        else
          raise TypeError, "can't add #{other.class} to Percentage"
        end
      end

      # Subtract percentages (clamped to 0%)
      #
      # @param other [Percentage, Numeric] Value to subtract
      # @return [Percentage] New percentage with difference of values
      def -(other)
        case other
        when Percentage
          Percentage.new([value - other.value, 0.0].max)
        when Numeric
          Percentage.new([value - other.to_f, 0.0].max)
        else
          raise TypeError, "can't subtract #{other.class} from Percentage"
        end
      end

      # Absolute value
      #
      # @return [Percentage] New percentage with absolute value
      def abs
        self.class.new(@value.abs)
      end

      # Check if percentage is zero
      #
      # @return [Boolean] true if percentage is 0.0
      def zero?
        @value.zero?
      end
    end
  end
end
