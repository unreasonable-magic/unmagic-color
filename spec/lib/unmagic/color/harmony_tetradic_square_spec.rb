# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#tetradic_square" do
    it "returns an array of 3 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.tetradic_square
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "returns colors at +90, +180, +270 degrees" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_square
      expect(result[0].hue.value).to(eq(90))
      expect(result[1].hue.value).to(eq(180))
      expect(result[2].hue.value).to(eq(270))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.tetradic_square
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end
  end
end
