# frozen_string_literal: true

module Unmagic
  class Color
    class RGB
      module Gradient
        # Linear gradient interpolation in RGB color space.
        #
        # Creates smooth color transitions by interpolating RGB components linearly
        # between color stops. Each color stop has a position (0.0-1.0) that defines
        # where the color appears in the gradient.
        #
        # ## RGB Interpolation
        #
        # RGB gradients interpolate the red, green, and blue components separately.
        # This can produce different visual results compared to HSL or OKLCH gradients,
        # especially when transitioning through complementary colors.
        #
        # ## Examples
        #
        #   # Simple horizontal gradient
        #   gradient = Unmagic::Color::RGB::Gradient::Linear.build(
        #     ["#FF0000", "#0000FF"],
        #     direction: "to right"
        #   )
        #   bitmap = gradient.rasterize(width: 10)
        #   bitmap.pixels[0].map(&:to_hex)
        #   #=> ["#ff0000", "#e60019", ..., "#0000ff"]
        #
        #   # Gradient with intermediate stops
        #   gradient = Unmagic::Color::RGB::Gradient::Linear.build(
        #     [
        #       ["#FF0000", 0.0],   # Red at start
        #       ["#00FF00", 0.5],   # Green at middle
        #       ["#0000FF", 1.0]    # Blue at end
        #     ],
        #     direction: "to bottom"
        #   )
        #   bitmap = gradient.rasterize(width: 1, height: 20)
        #
        #   # Angled gradient
        #   gradient = Unmagic::Color::RGB::Gradient::Linear.build(
        #     ["#FF0000", "#0000FF"],
        #     direction: "45deg"
        #   )
        #   bitmap = gradient.rasterize(width: 100, height: 100)
        #
        #   # Use Stop objects directly
        #   stops = [
        #     Unmagic::Color::Gradient::Stop.new(
        #       color: Unmagic::Color::RGB.parse("#FF0000"),
        #       position: 0.0
        #     ),
        #     Unmagic::Color::Gradient::Stop.new(
        #       color: Unmagic::Color::RGB.parse("#0000FF"),
        #       position: 1.0
        #     )
        #   ]
        #   direction = Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT
        #   gradient = Unmagic::Color::RGB::Gradient::Linear.new(stops, direction: direction)
        class Linear < Unmagic::Color::Gradient::Base
          class << self
            # Get the RGB color class.
            #
            # @return [Class] Unmagic::Color::RGB
            def color_class
              Unmagic::Color::RGB
            end
          end

          # Rasterize the gradient to a bitmap.
          #
          # Generates a bitmap containing the gradient with support for angled directions.
          # The direction is determined by the gradient's direction parameter.
          #
          # @param width [Integer] Width of the bitmap (default 1)
          # @param height [Integer] Height of the bitmap (default 1)
          # @return [Bitmap] A bitmap with the specified dimensions
          #
          # @raise [Error] If width or height is less than 1
          def rasterize(width: 1, height: 1)
            raise self.class::Error, "width must be at least 1" if width < 1
            raise self.class::Error, "height must be at least 1" if height < 1

            # Get the angle from the direction's "to" component
            degrees = @direction.to.value

            # Generate pixels row by row
            pixels = Array.new(height) do |y|
              Array.new(width) do |x|
                position = calculate_position(x, y, width, height, degrees)
                color_at_position(position)
              end
            end

            Unmagic::Color::Gradient::Bitmap.new(
              width: width,
              height: height,
              pixels: pixels,
            )
          end

          private

          def validate_color_types(stops)
            stops.each_with_index do |stop, i|
              unless stop.color.is_a?(Unmagic::Color::RGB)
                raise self.class::Error, "stops[#{i}].color must be an RGB color"
              end
            end
          end

          # Calculate the position (0-1) of a pixel in the gradient.
          #
          # @param x [Integer] X coordinate
          # @param y [Integer] Y coordinate
          # @param width [Integer] Bitmap width
          # @param height [Integer] Bitmap height
          # @param degrees [Float] Gradient angle in degrees
          # @return [Float] Position along gradient (0.0 to 1.0)
          def calculate_position(x, y, width, height, degrees)
            # Normalize coordinates to 0-1 range
            nx = width > 1 ? x / (width - 1).to_f : 0.5
            ny = height > 1 ? y / (height - 1).to_f : 0.5

            # Calculate position based on angle
            angle_rad = degrees * Math::PI / 180.0

            # The gradient line goes in the direction of the angle
            # 0° = to top (upward)
            # 90° = to right
            # 180° = to bottom (downward)
            # 270° = to left
            dx = Math.sin(angle_rad)
            dy = Math.cos(angle_rad)

            # Calculate position by projecting pixel onto gradient direction
            # We want position 0 at the start and position 1 at the end
            position = (nx - 0.5) * dx + (0.5 - ny) * dy + 0.5

            # Clamp to valid range
            position.clamp(0.0, 1.0)
          end

          # Get the color at a specific position in the gradient.
          #
          # @param position [Float] Position along gradient (0.0 to 1.0)
          # @return [Color] The interpolated color at this position
          def color_at_position(position)
            start_stop, end_stop = find_bracket_stops(position)

            if start_stop.position == end_stop.position
              start_stop.color
            else
              segment_length = end_stop.position - start_stop.position
              blend_amount = (position - start_stop.position) / segment_length
              start_stop.color.blend(end_stop.color, blend_amount)
            end
          end
        end
      end
    end
  end
end
