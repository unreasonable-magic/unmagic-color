# frozen_string_literal: true

module Unmagic
  class Color
    class HSL
      # Gradient generation in HSL color space.
      module Gradient
        # Linear gradient interpolation in HSL color space.
        #
        # Creates smooth color transitions by interpolating hue, saturation, and
        # lightness separately. HSL gradients often produce more visually pleasing
        # results than RGB for transitions across the color wheel.
        #
        # ## HSL Interpolation
        #
        # HSL gradients interpolate through the color wheel (hue), which can create
        # smoother transitions through vivid colors. The hue component uses shortest-arc
        # interpolation via the existing blend method.
        #
        # ## Examples
        #
        #   # Rainbow gradient
        #   gradient = Unmagic::Color::HSL::Gradient::Linear.build(
        #     [
        #       ["hsl(0, 100%, 50%)", 0.0],     # Red
        #       ["hsl(120, 100%, 50%)", 0.5],   # Green
        #       ["hsl(240, 100%, 50%)", 1.0]    # Blue
        #     ],
        #     direction: "to right"
        #   )
        #   bitmap = gradient.rasterize(width: 100)
        #
        #   # Simple two-color gradient
        #   gradient = Unmagic::Color::HSL::Gradient::Linear.build(
        #     ["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"],
        #     direction: "to bottom"
        #   )
        #   bitmap = gradient.rasterize(width: 1, height: 50)
        #
        #   # Angled gradient with color objects
        #   gradient = Unmagic::Color::HSL::Gradient::Linear.build(
        #     [
        #       Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50),
        #       Unmagic::Color::HSL.new(hue: 240, saturation: 100, lightness: 50)
        #     ],
        #     direction: "45deg"
        #   )
        #   bitmap = gradient.rasterize(width: 100, height: 100)
        class Linear < Unmagic::Color::Gradient::Base
          class << self
            # Get the HSL color class.
            #
            # @return [Class] Unmagic::Color::HSL
            def color_class
              Unmagic::Color::HSL
            end
          end

          # Rasterize the gradient to a bitmap.
          #
          # Generates a bitmap containing the gradient with support for angled directions.
          # Hue interpolation uses shortest-arc blending for smooth color wheel transitions.
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
              unless stop.color.is_a?(Unmagic::Color::HSL)
                raise self.class::Error, "stops[#{i}].color must be an HSL color"
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
