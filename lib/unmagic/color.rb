# frozen_string_literal: true

require_relative "color/rgb"
require_relative "color/rgb/hex"
require_relative "color/hsl"

module Unmagic
  # Module for color representations and parsing
  module Color
    # Parse a color string and return the appropriate Color object
    def self.parse(input)
      return nil unless input.is_a?(String)

      input = input.strip

      # Try hex first (most common)
      if input.start_with?("#") || input.match?(/\A[0-9A-Fa-f]{3,6}\z/)
        RGB::Hex.parse(input)
        # RGB format
      elsif input.start_with?("rgb")
        RGB.parse(input)
        # HSL format
      elsif input.start_with?("hsl")
        HSL.parse(input)
        # Try as hex without #
      elsif input.match?(/\A[0-9A-Fa-f]{6}\z/)
        RGB::Hex.parse(input)
      else
        nil
      end
    end

    # Create a color from HSL values
    def self.from_hsl(hue, saturation, lightness)
      HSL.new(hue: hue, saturation: saturation, lightness: lightness)
    end

    # Convenience constructor that accepts hex strings or Color objects
    def self.new(input = nil, **kwargs)
      if input.is_a?(String)
        parse(input) || RGB.new(**kwargs)
      elsif input.respond_to?(:to_rgb)
        input
      elsif input.nil? && !kwargs.empty?
        RGB.new(**kwargs)
      elsif input.is_a?(Hash)
        RGB.new(**input)
      else
        RGB.new(red: 0, green: 0, blue: 0)
      end
    end
  end
end