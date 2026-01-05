# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#shades" do
    it "returns an array of darker colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.shades(steps: 3)
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "creates progressively darker colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 60)
      result = color.shades(steps: 3)
      lightnesses = result.map { |c| c.lightness.value }

      # All should be darker than original
      expect(lightnesses.all? { |l| l < 60 }).to(be(true))
      # Should be in descending order (getting darker)
      expect(lightnesses).to(eq(lightnesses.sort.reverse))
    end

    it "respects amount parameter" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 60)
      result_small = color.shades(steps: 3, amount: 0.3)
      result_large = color.shades(steps: 3, amount: 0.9)

      # Larger amount should produce darker shades
      expect(result_large.last.lightness.value).to(be < result_small.last.lightness.value)
    end

    it "preserves hue and saturation" do
      color = Unmagic::Color::HSL.new(hue: 120, saturation: 80, lightness: 50)
      result = color.shades(steps: 3)
      expect(result.all? { |c| c.hue.value == 120 }).to(be(true))
      expect(result.all? { |c| c.saturation.value == 80 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 120, saturation: 80, lightness: 50, alpha: 60)
      result = color.shades(steps: 3)
      expect(result.all? { |c| c.alpha.value == 60 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.shades(steps: 3)
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end

    it "clamps lightness to 0" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 10)
      result = color.shades(steps: 5, amount: 1.0)
      expect(result.last.lightness.value).to(be >= 0)
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#FF0000")
      expect { color.shades(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end
end
