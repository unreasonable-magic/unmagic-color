# frozen_string_literal: true

module Unmagic
  class Color
    module Gradient
      # A color stop at a specific position in a gradient.
      #
      # Represents a single color at a position along a gradient. Positions are
      # normalized from 0.0 (start) to 1.0 (end). Multiple stops define the
      # color transitions in a gradient.
      #
      # ## Usage
      #
      # Stop objects are typically created automatically by gradient classes
      # using the `.build()` method, but can be created directly for more control.
      #
      # ## Examples
      #
      #   # Create a stop directly
      #   stop = Unmagic::Color::Gradient::Stop.new(
      #     color: Unmagic::Color::RGB.parse("#FF0000"),
      #     position: 0.5
      #   )
      #
      #   # Access stop properties
      #   stop.color      # => #<RGB...>
      #   stop.position   # => 0.5
      class Stop
        attr_reader :color, :position

        # Create a new color stop.
        #
        # @param color [Color] The color at this stop (must be a Color instance)
        # @param position [Numeric] Position along gradient (0.0-1.0)
        #
        # @raise [ArgumentError] If color is not a Color instance
        # @raise [ArgumentError] If position is not between 0.0 and 1.0
        def initialize(color:, position:)
          raise ArgumentError, "color must be a Color instance" unless color.is_a?(Unmagic::Color)
          raise ArgumentError, "position must be between 0.0 and 1.0" if position < 0.0 || position > 1.0

          @color = color
          @position = position.to_f
        end
      end
    end
  end
end
