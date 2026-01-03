# frozen_string_literal: true

module Unmagic
  class Color
    module Gradient
      # Base class for gradient implementations.
      #
      # Provides shared functionality for all gradient types. Subclasses must
      # override `color_class` and `validate_color_types` to specify their color space.
      #
      # ## Subclass Requirements
      #
      # Subclasses must implement:
      # - `.color_class` - Returns the color class (RGB, HSL, or OKLCH)
      # - `#validate_color_types(stops)` - Validates all stops have correct color type
      # - `#rasterize` - Generates a Bitmap from the gradient
      #
      # ## Examples
      #
      #   # Subclasses use this base class
      #   class RGB::Gradient::Linear < Gradient::Base
      #     def self.color_class
      #       Unmagic::Color::RGB
      #     end
      #
      #     def validate_color_types(stops)
      #       # Validation logic...
      #     end
      #
      #     def rasterize
      #       # Rasterization logic...
      #     end
      #   end
      class Base
        class Error < Color::Error; end

        attr_reader :stops, :direction

        class << self
          # Get the color class for this gradient type.
          #
          # Subclasses must override this to return their color class.
          #
          # @return [Class] The color class (RGB, HSL, or OKLCH)
          # @raise [NotImplementedError] If not overridden by subclass
          def color_class
            raise NotImplementedError, "Subclasses must define color_class"
          end

          # Build a gradient from colors or color/position tuples.
          #
          # Convenience factory method that converts colors to Stop objects
          # and creates a gradient. Accepts both color objects and strings
          # (strings are parsed using the color class's parse method).
          #
          # Works like CSS linear-gradient - you can mix positioned and non-positioned colors.
          # Non-positioned colors auto-balance between their surrounding positioned neighbors.
          #
          # @param colors_or_tuples [Array] Array of colors or [color, position] pairs (can be mixed)
          # @param direction [String, Numeric, Degrees, Direction, nil] Optional gradient direction
          #   - Direction strings: "to top", "from left to right", "45deg", "90°"
          #   - Numeric degrees: 45, 90, 180
          #   - Degrees/Direction instances
          #   - Defaults to "to bottom" (180°) if omitted
          # @return [Base] New gradient instance
          #
          # @example All auto-balanced positions
          #   RGB::Gradient::Linear.build(["#FF0000", "#00FF00", "#0000FF"])
          #   # Positions: 0.0, 0.5, 1.0
          #
          # @example All explicit positions
          #   RGB::Gradient::Linear.build([["#FF0000", 0.0], ["#00FF00", 0.3], ["#0000FF", 1.0]])
          #
          # @example Mixed positions (like CSS linear-gradient)
          #   RGB::Gradient::Linear.build(["#FF0000", ["#FFFF00", 0.3], "#00FF00", ["#0000FF", 0.9], "#FF00FF"])
          #   # Positions: 0.0, 0.3, 0.6, 0.9, 1.0
          #   # (red at start, yellow at 30%, green auto-balances at 60%, blue at 90%, purple at end)
          #
          # @example With direction keyword
          #   RGB::Gradient::Linear.build(["#FF0000", "#0000FF"], direction: "to right")
          #   RGB::Gradient::Linear.build(["#FF0000", "#0000FF"], direction: "from left to right")
          #
          # @example With numeric direction
          #   RGB::Gradient::Linear.build(["#FF0000", "#0000FF"], direction: 45)
          #   RGB::Gradient::Linear.build(["#FF0000", "#0000FF"], direction: "90deg")
          def build(colors_or_tuples, direction: nil)
            # Parse colors and detect which have explicit positions
            parsed = colors_or_tuples.map do |item|
              if item.is_a?(::Array)
                # Explicit position tuple
                color_or_string, position = item
                color = if color_or_string.is_a?(::String)
                  # Use universal parser for strings (handles named colors, hex, rgb(), hsl(), etc.)
                  parsed_color = Unmagic::Color[color_or_string]
                  # Convert to the gradient's color space if needed
                  convert_to_color_space(parsed_color)
                else
                  color_or_string
                end
                { color: color, position: position }
              else
                # No position, will auto-balance
                color = if item.is_a?(::String)
                  # Use universal parser for strings
                  parsed_color = Unmagic::Color[item]
                  # Convert to the gradient's color space if needed
                  convert_to_color_space(parsed_color)
                else
                  item
                end
                { color: color, position: nil }
              end
            end

            # Auto-balance positions for items without explicit positions
            # Pass 1: Set first and last items if they don't have positions
            unless parsed.first[:position]
              parsed.first[:position] = 0.0
            end
            unless parsed.last[:position]
              parsed.last[:position] = 1.0
            end

            # Pass 2: Auto-balance middle items
            parsed.each_with_index do |item, i|
              next if item[:position] # Already has position

              # Find previous positioned stop
              prev_pos = nil
              prev_index = nil
              (i - 1).downto(0) do |j|
                if parsed[j][:position]
                  prev_pos = parsed[j][:position]
                  prev_index = j
                  break
                end
              end

              # Find next positioned stop
              next_pos = nil
              next_index = nil
              ((i + 1)...parsed.length).each do |j|
                if parsed[j][:position]
                  next_pos = parsed[j][:position]
                  next_index = j
                  break
                end
              end

              # Count items in this unpositioned group
              group_size = next_index - prev_index - 1
              group_index = i - prev_index - 1

              # Evenly distribute within the range
              item[:position] = prev_pos + (next_pos - prev_pos) * (group_index + 1) / (group_size + 1).to_f
            end

            # Create Stop objects
            stops = parsed.map do |item|
              Unmagic::Color::Gradient::Stop.new(color: item[:color], position: item[:position])
            end

            new(stops, direction: direction)
          end

          private

          # Convert a color to this gradient's color space.
          #
          # @param color [Color] The color to convert
          # @return [Color] The color in the gradient's color space
          def convert_to_color_space(color)
            target_class = color_class
            return color if color.is_a?(target_class)

            # Convert to the target color space
            case target_class.name
            when "Unmagic::Color::RGB"
              color.to_rgb
            when "Unmagic::Color::HSL"
              color.to_hsl
            when "Unmagic::Color::OKLCH"
              color.to_oklch
            else
              color
            end
          end
        end

        # Create a new gradient.
        #
        # @param stops [Array<Stop>] Array of color stops
        # @param direction [Direction, nil] Optional Direction instance (defaults to TOP_TO_BOTTOM)
        #
        # @raise [Error] If stops is not an array
        # @raise [Error] If there are fewer than 2 stops
        # @raise [Error] If any stop is not a Stop object
        # @raise [Error] If stops are not sorted by position
        def initialize(stops, direction: nil)
          raise Error, "stops must be an array" unless stops.is_a?(Array)
          raise Error, "must have at least 2 stops" if stops.length < 2

          stops.each_with_index do |stop, i|
            unless stop.is_a?(Unmagic::Color::Gradient::Stop)
              raise Error, "stops[#{i}] must be a Stop object"
            end
          end

          validate_color_types(stops)

          stops.each_cons(2) do |a, b|
            if a.position > b.position
              raise Error, "stops must be sorted by position"
            end
          end

          @stops = stops
          @direction = direction
        end

        private

        # Validate that all stops have the correct color type.
        #
        # Subclasses must override this to check color types.
        #
        # @param stops [Array<Stop>] Array of stops to validate
        # @raise [NotImplementedError] If not overridden by subclass
        def validate_color_types(stops)
          raise NotImplementedError, "Subclasses must implement validate_color_types"
        end

        # Find the two stops that bracket a given position.
        #
        # Returns the start and end stops for the segment containing the position.
        # Used during interpolation to find which colors to blend.
        #
        # @param position [Float] Position to find (0.0-1.0)
        # @return [Array<Stop, Stop>] The [start_stop, end_stop] that bracket the position
        def find_bracket_stops(position)
          @stops.each_cons(2) do |start_stop, end_stop|
            if position >= start_stop.position && position <= end_stop.position
              return [start_stop, end_stop]
            end
          end
          [@stops[-2], @stops[-1]]
        end
      end
    end
  end
end
