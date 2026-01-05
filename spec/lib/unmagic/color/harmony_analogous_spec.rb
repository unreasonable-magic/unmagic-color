# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#analogous" do
    it "returns an array of 2 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.analogous
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(2))
    end

    it "returns colors at -30 and +30 degrees by default" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 100, lightness: 50)
      result = color.analogous
      expect(result[0].hue.value).to(eq(30))  # 60 - 30
      expect(result[1].hue.value).to(eq(90))  # 60 + 30
    end

    it "accepts custom angle" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 100, lightness: 50)
      result = color.analogous(angle: 15)
      expect(result[0].hue.value).to(eq(45))  # 60 - 15
      expect(result[1].hue.value).to(eq(75))  # 60 + 15
    end

    it "wraps hue correctly for negative angles" do
      color = Unmagic::Color::HSL.new(hue: 10, saturation: 100, lightness: 50)
      result = color.analogous
      expect(result[0].hue.value).to(eq(340)) # 10 - 30 = -20 -> 340
      expect(result[1].hue.value).to(eq(40))  # 10 + 30
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.analogous
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end
  end
end
