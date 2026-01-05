# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#triadic" do
    it "returns an array of 2 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.triadic
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(2))
    end

    it "returns colors at +120 and +240 degrees" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.triadic
      expect(result[0].hue.value).to(eq(120))
      expect(result[1].hue.value).to(eq(240))
    end

    it "wraps hue correctly" do
      color = Unmagic::Color::HSL.new(hue: 200, saturation: 100, lightness: 50)
      result = color.triadic
      expect(result[0].hue.value).to(eq(320)) # 200 + 120
      expect(result[1].hue.value).to(eq(80))  # 200 + 240 = 440 % 360 = 80
    end

    it "preserves color space" do
      color = Unmagic::Color::OKLCH.new(lightness: 0.6, chroma: 0.15, hue: 0)
      result = color.triadic
      expect(result.all? { |c| c.is_a?(Unmagic::Color::OKLCH) }).to(be(true))
    end
  end
end
