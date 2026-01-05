# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#monochromatic" do
    it "returns an array of colors" do
      color = Unmagic::Color.parse("#0000FF")
      result = color.monochromatic
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(5))
    end

    it "accepts custom step count" do
      color = Unmagic::Color.parse("#0000FF")
      result = color.monochromatic(steps: 3)
      expect(result.length).to(eq(3))
    end

    it "creates colors with varying lightness" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 100, lightness: 50)
      result = color.monochromatic(steps: 5)

      lightnesses = result.map { |c| c.lightness.value }
      # Should go from 15% to 85%
      expect(lightnesses.first).to(eq(15))
      expect(lightnesses.last).to(eq(85))
      # Should be sorted (ascending)
      expect(lightnesses).to(eq(lightnesses.sort))
    end

    it "preserves hue and saturation" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 80, lightness: 50)
      result = color.monochromatic(steps: 3)
      expect(result.all? { |c| c.hue.value == 240 }).to(be(true))
      expect(result.all? { |c| c.saturation.value == 80 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 100, lightness: 50, alpha: 75)
      result = color.monochromatic(steps: 3)
      expect(result.all? { |c| c.alpha.value == 75 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#0000FF")
      result = color.monochromatic
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#0000FF")
      expect { color.monochromatic(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end
end
