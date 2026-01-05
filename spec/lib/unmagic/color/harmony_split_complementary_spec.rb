# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#split_complementary" do
    it "returns an array of 2 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.split_complementary
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(2))
    end

    it "returns colors at 150 and 210 degrees by default" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.split_complementary
      expect(result[0].hue.value).to(eq(150)) # 180 - 30
      expect(result[1].hue.value).to(eq(210)) # 180 + 30
    end

    it "accepts custom angle" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.split_complementary(angle: 45)
      expect(result[0].hue.value).to(eq(135)) # 180 - 45
      expect(result[1].hue.value).to(eq(225)) # 180 + 45
    end

    it "preserves color space" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.split_complementary
      expect(result.all? { |c| c.is_a?(Unmagic::Color::HSL) }).to(be(true))
    end
  end
end
