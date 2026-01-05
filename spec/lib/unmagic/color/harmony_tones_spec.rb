# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#tones" do
    it "returns an array of desaturated colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tones(steps: 3)
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "creates progressively less saturated colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tones(steps: 3)
      saturations = result.map { |c| c.saturation.value }

      # All should be less saturated than original
      expect(saturations.all? { |s| s < 100 }).to(be(true))
      # Should be in descending order (getting less saturated)
      expect(saturations).to(eq(saturations.sort.reverse))
    end

    it "respects amount parameter" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result_small = color.tones(steps: 3, amount: 0.3)
      result_large = color.tones(steps: 3, amount: 0.9)

      # Larger amount should produce less saturated tones
      expect(result_large.last.saturation.value).to(be < result_small.last.saturation.value)
    end

    it "preserves hue and lightness" do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 80, lightness: 60)
      result = color.tones(steps: 3)
      expect(result.all? { |c| c.hue.value == 180 }).to(be(true))
      expect(result.all? { |c| c.lightness.value == 60 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 80, lightness: 60, alpha: 90)
      result = color.tones(steps: 3)
      expect(result.all? { |c| c.alpha.value == 90 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#00FF00")
      result = color.tones(steps: 3)
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end

    it "clamps saturation to 0" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 20, lightness: 50)
      result = color.tones(steps: 5, amount: 1.0)
      expect(result.last.saturation.value).to(be >= 0)
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#00FF00")
      expect { color.tones(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end
end
