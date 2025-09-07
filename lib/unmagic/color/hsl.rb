# frozen_string_literal: true

module Unmagic
  class Color
    # HSL color representation
    class HSL < Unmagic::Color
        attr_reader :hue, :saturation, :lightness
        
        # Check if a string is a valid HSL color
        def self.valid?(value)
          return false unless value.is_a?(String)
          
          # Remove hsl() wrapper if present
          clean = value.gsub(/^hsl\s*\(\s*|\s*\)$/, "").strip
          
          # Split values
          parts = clean.split(/\s*,\s*/)
          return false unless parts.length == 3
          
          # Check hue (0-360)
          h = parts[0].strip
          return false unless h.match?(/\A\d+(\.\d+)?\z/)
          h_val = h.to_f
          return false unless h_val >= 0 && h_val <= 360
          
          # Check saturation and lightness (0-100%)
          s = parts[1].gsub("%", "").strip
          l = parts[2].gsub("%", "").strip
          
          return false unless s.match?(/\A\d+(\.\d+)?\z/)
          return false unless l.match?(/\A\d+(\.\d+)?\z/)
          
          s_val = s.to_f
          l_val = l.to_f
          return false unless s_val >= 0 && s_val <= 100
          return false unless l_val >= 0 && l_val <= 100
          
          true
        rescue
          false
        end

        def initialize(hue:, saturation:, lightness:)
          @hue = hue.to_f % 360
          # Store as percentages (0-100) for consistency
          @saturation = saturation.to_f.clamp(0, 100)
          @lightness = lightness.to_f.clamp(0, 100)
          
          # Convert to RGB for base class
          rgb = hsl_to_rgb
          super(red: rgb[0], green: rgb[1], blue: rgb[2])
        end

        # Parse HSL string like "hsl(180, 50%, 50%)" or "180, 50%, 50%"
        def self.parse(input)
          return nil unless input.is_a?(String)
          
          # Remove hsl() wrapper if present
          clean = input.gsub(/^hsl\s*\(\s*|\s*\)$/, "").strip
          
          # Split and parse values
          parts = clean.split(/\s*,\s*/)
          return nil unless parts.length == 3
          
          # Check if hue is numeric
          h_str = parts[0].strip
          return nil unless h_str.match?(/\A\d+(\.\d+)?\z/)
          
          # Check if saturation and lightness are numeric (with optional %)
          s_str = parts[1].gsub("%", "").strip
          l_str = parts[2].gsub("%", "").strip
          return nil unless s_str.match?(/\A\d+(\.\d+)?\z/)
          return nil unless l_str.match?(/\A\d+(\.\d+)?\z/)
          
          h = h_str.to_f
          s = s_str.to_f
          l = l_str.to_f
          
          new(hue: h, saturation: s, lightness: l)
        rescue
          nil
        end

        def to_hsl
          self
        end

        private

        def hsl_to_rgb
          h = @hue / 360.0
          s = @saturation / 100.0  # Convert percentage to 0-1
          l = @lightness / 100.0    # Convert percentage to 0-1

          if s == 0
            # Achromatic
            gray = (l * 255).round
            [gray, gray, gray]
          else
            q = l < 0.5 ? l * (1 + s) : l + s - l * s
            p = 2 * l - q

            r = hue_to_rgb(p, q, h + 1/3.0)
            g = hue_to_rgb(p, q, h)
            b = hue_to_rgb(p, q, h - 1/3.0)

            [(r * 255).round, (g * 255).round, (b * 255).round]
          end
        end

        def hue_to_rgb(p, q, t)
          t += 1 if t < 0
          t -= 1 if t > 1

          if t < 1/6.0
            p + (q - p) * 6 * t
          elsif t < 1/2.0
            q
          elsif t < 2/3.0
            p + (q - p) * (2/3.0 - t) * 6
          else
            p
          end
        end
    end
  end
end