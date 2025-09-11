# frozen_string_literal: true

module Unmagic
  class Color
    class OKLCH < Color
        class ParseError < Color::Error; end

        attr_reader :lightness, :chroma, :hue


        def initialize(lightness:, chroma:, hue:)
          @lightness = Color::Lightness.new(lightness * 100) # Convert 0-1 to percentage
          @chroma = Color::Chroma.new(value: chroma)
          @hue = Color::Hue.new(value: hue)
        end

        # Return unit instances directly, but lightness as ratio for OKLCH
        def lightness = @lightness.to_ratio
        def chroma = @chroma
        def hue = @hue

        # Helper method for working with lightness in percentage form
        def lightness_percentage = @lightness.value

        # Parse OKLCH string like "oklch(0.58 0.15 180)" or "0.58 0.15 180"
        def self.parse(input)
          raise ParseError.new("Input must be a string") unless input.is_a?(String)

          # Remove oklch() wrapper if present
          clean = input.gsub(/^oklch\s*\(\s*|\s*\)$/, "").strip

          # Split values
          parts = clean.split(/\s+/)
          unless parts.length == 3
            raise ParseError.new("Expected 3 OKLCH values, got #{parts.length}")
          end

          # Check if all values are numeric
          parts.each_with_index do |v, i|
            unless v.match?(/\A\d+(\.\d+)?\z/)
              component = %w[lightness chroma hue][i]
              raise ParseError.new("Invalid #{component} value: #{v.inspect} (must be a number)")
            end
          end

          # Convert to floats
          l = parts[0].to_f
          c = parts[1].to_f
          h = parts[2].to_f

          # Validate ranges
          unless l >= 0 && l <= 1
            raise ParseError.new("Lightness must be between 0 and 1, got #{l}")
          end

          unless c >= 0 && c <= 0.5
            raise ParseError.new("Chroma must be between 0 and 0.5, got #{c}")
          end

          unless h >= 0 && h < 360
            raise ParseError.new("Hue must be between 0 and 360, got #{h}")
          end

          new(lightness: l, chroma: c, hue: h)
        end

        # Factory: deterministic OKLCH from integer seed
        # Produces stable colors from hash function output. Tweak ranges to taste.
        def self.derive(seed, lightness: 0.58, chroma_range: (0.10..0.18), hue_spread: 997, hue_base: 137.508)
          raise ArgumentError.new("Seed must be an integer") unless seed.is_a?(Integer)
          
          h32 = seed & 0xFFFFFFFF # Ensure 32-bit

          # Hue: golden-angle style distribution to avoid clusters
          h = (hue_base * (h32 % hue_spread)) % 360

          # Chroma: map a byte into a safe text-friendly range
          c = chroma_range.begin + ((h32 >> 8) & 0xFF) / 255.0 * (chroma_range.end - chroma_range.begin)

          new(lightness: lightness, chroma: c, hue: h)
        end

        # Convert to OKLCH representation (returns self)
        def to_oklch
          self
        end

        # Convert to RGB (placeholder - would need complex conversion)
        def to_rgb
          # For now, convert via approximation - would need proper OKLCH->sRGB conversion
          # This is a simplified placeholder that approximates RGB from OKLCH
          require_relative "rgb"

          # Simple approximation: use lightness and chroma to estimate RGB
          base = (@lightness.to_ratio * 255).round
          saturation = (@chroma * 255).value

          # Convert hue to RGB ratios (very simplified)
          h_rad = (@hue * Math::PI / 180).value
          r_offset = (Math.cos(h_rad) * saturation).round
          g_offset = (Math.cos(h_rad + 2 * Math::PI / 3) * saturation).round
          b_offset = (Math.cos(h_rad + 4 * Math::PI / 3) * saturation).round

          r = (base + r_offset).clamp(0, 255)
          g = (base + g_offset).clamp(0, 255)
          b = (base + b_offset).clamp(0, 255)

          Unmagic::Color::RGB.new(red: r, green: g, blue: b)
        end

        def luminance
          # OKLCH lightness is perceptually uniform, so we can use it directly
          @lightness.to_ratio # Return 0-1 range
        end

        # Light edit helpers
        def lighten(amount = 0.03)
          current_lightness = @lightness.to_ratio
          new_lightness = clamp01(current_lightness + amount)
          self.class.new(lightness: new_lightness, chroma: @chroma.value, hue: @hue.value)
        end

        def darken(amount = 0.03)
          current_lightness = @lightness.to_ratio
          new_lightness = clamp01(current_lightness - amount)
          self.class.new(lightness: new_lightness, chroma: @chroma.value, hue: @hue.value)
        end

        def saturate(amount = 0.02)
          new_chroma = [ @chroma.value + amount, 0.4 ].min
          self.class.new(lightness: @lightness.to_ratio, chroma: new_chroma, hue: @hue.value)
        end

        def desaturate(amount = 0.02)
          new_chroma = [ @chroma.value - amount, 0.0 ].max
          self.class.new(lightness: @lightness.to_ratio, chroma: new_chroma, hue: @hue.value)
        end

        def rotate(amount = 10)
          new_hue = (@hue.value + amount) % 360
          self.class.new(lightness: @lightness.to_ratio, chroma: @chroma.value, hue: new_hue)
        end

        # Blend with another color
        def blend(other, amount = 0.5)
          amount = amount.to_f.clamp(0, 1)
          other_oklch = other.respond_to?(:to_oklch) ? other.to_oklch : other

          # Blend in OKLCH space with shortest-arc hue interpolation
          dh = (((other_oklch.hue.value - @hue.value + 540) % 360) - 180)
          new_hue = (@hue.value + dh * amount) % 360
          new_lightness = @lightness.to_ratio + (other_oklch.lightness.to_ratio - @lightness.to_ratio) * amount
          new_chroma = @chroma.value + (other_oklch.chroma.value - @chroma.value) * amount

          self.class.new(lightness: new_lightness, chroma: new_chroma, hue: new_hue)
        end


        # CSS output - as an oklch() color literal
        def to_css_oklch
          format("oklch(%.4f %.4f %.2f)", @lightness.to_ratio, @chroma.value, @hue.value)
        end

        # As CSS variables for runtime mixing
        def to_css_vars
          format("--ul:%.4f;--uc:%.4f;--uh:%.2f;", @lightness.to_ratio, @chroma.value, @hue.value)
        end

        # Build a color-mix string
        def to_css_color_mix(bg_css = "var(--bg)", a_pct: 72, bg_pct: 28)
          "color-mix(in oklch, #{to_css_oklch} #{a_pct}%, #{bg_css} #{bg_pct}%)"
        end

        def ==(other)
          other.is_a?(Unmagic::Color::OKLCH) &&
            (@lightness.to_ratio - other.lightness.to_ratio).abs < 0.01 &&
            (@chroma.value - other.chroma.value).abs < 0.01 &&
            (@hue.value - other.hue.value).abs < 0.01
        end

        def to_s
          to_css_oklch
        end

        private

        def clamp01(x)
          [ [ x, 0.0 ].max, 1.0 ].min
        end

    end
  end
end
