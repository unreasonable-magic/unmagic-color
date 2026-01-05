# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#tetradic_rectangle" do
    it "returns an array of 3 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.tetradic_rectangle
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "returns colors at +60, +180, +240 degrees by default" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_rectangle
      expect(result[0].hue.value).to(eq(60))
      expect(result[1].hue.value).to(eq(180))
      expect(result[2].hue.value).to(eq(240))
    end

    it "accepts custom angle" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_rectangle(angle: 30)
      expect(result[0].hue.value).to(eq(30))
      expect(result[1].hue.value).to(eq(180))
      expect(result[2].hue.value).to(eq(210))
    end

    it "preserves color space" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_rectangle
      expect(result.all? { |c| c.is_a?(Unmagic::Color::HSL) }).to(be(true))
    end
  end
end
