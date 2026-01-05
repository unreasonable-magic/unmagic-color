# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#complementary" do
    it "returns a single color (not an array)" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.complementary
      expect(result).not_to(be_an(Array))
      expect(result).to(be_a(Unmagic::Color))
    end

    it "returns the complement with 180 degree hue shift" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.complementary
      expect(result.hue.value).to(eq(180))
    end

    it "wraps hue correctly" do
      color = Unmagic::Color::HSL.new(hue: 270, saturation: 100, lightness: 50)
      result = color.complementary
      expect(result.hue.value).to(eq(90)) # 270 + 180 = 450 % 360 = 90
    end

    it "preserves saturation and lightness" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 75, lightness: 40)
      result = color.complementary
      expect(result.saturation.value).to(eq(75))
      expect(result.lightness.value).to(eq(40))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 75, lightness: 40, alpha: 50)
      result = color.complementary
      expect(result.alpha.value).to(eq(50))
    end

    it "preserves color space for RGB input" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.complementary
      expect(result).to(be_a(Unmagic::Color::RGB))
    end

    it "preserves color space for HSL input" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.complementary
      expect(result).to(be_a(Unmagic::Color::HSL))
    end

    it "preserves color space for OKLCH input" do
      color = Unmagic::Color::OKLCH.new(lightness: 0.6, chroma: 0.15, hue: 30)
      result = color.complementary
      expect(result).to(be_a(Unmagic::Color::OKLCH))
    end
  end
end
