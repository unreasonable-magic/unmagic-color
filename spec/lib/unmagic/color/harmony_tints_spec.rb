# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#tints" do
    it "returns an array of lighter colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tints(steps: 3)
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "creates progressively lighter colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 40)
      result = color.tints(steps: 3)
      lightnesses = result.map { |c| c.lightness.value }

      # All should be lighter than original
      expect(lightnesses.all? { |l| l > 40 }).to(be(true))
      # Should be in ascending order (getting lighter)
      expect(lightnesses).to(eq(lightnesses.sort))
    end

    it "respects amount parameter" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 40)
      result_small = color.tints(steps: 3, amount: 0.3)
      result_large = color.tints(steps: 3, amount: 0.9)

      # Larger amount should produce lighter tints
      expect(result_large.last.lightness.value).to(be > result_small.last.lightness.value)
    end

    it "preserves hue and saturation" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 70, lightness: 50)
      result = color.tints(steps: 3)
      expect(result.all? { |c| c.hue.value == 240 }).to(be(true))
      expect(result.all? { |c| c.saturation.value == 70 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 70, lightness: 50, alpha: 80)
      result = color.tints(steps: 3)
      expect(result.all? { |c| c.alpha.value == 80 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color::OKLCH.new(lightness: 0.5, chroma: 0.15, hue: 30)
      result = color.tints(steps: 3)
      expect(result.all? { |c| c.is_a?(Unmagic::Color::OKLCH) }).to(be(true))
    end

    it "clamps lightness to 100" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 90)
      result = color.tints(steps: 5, amount: 1.0)
      expect(result.last.lightness.value).to(be <= 100)
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#0000FF")
      expect { color.tints(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end
end
