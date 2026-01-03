# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::HSL::Gradient::Linear) do
  describe ".color_class" do
    it "returns HSL class" do
      expect(described_class.color_class).to(eq(Unmagic::Color::HSL))
    end
  end

  describe ".build" do
    it "builds gradient from color strings" do
      gradient = described_class.build(["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"])
      expect(gradient.stops.length).to(eq(2))
      expect(gradient.stops[0].color).to(be_a(Unmagic::Color::HSL))
      expect(gradient.stops[1].color).to(be_a(Unmagic::Color::HSL))
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(eq(1.0))
    end

    it "builds gradient from color objects" do
      red = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      blue = Unmagic::Color::HSL.new(hue: 240, saturation: 100, lightness: 50)
      gradient = described_class.build([red, blue])
      expect(gradient.stops.length).to(eq(2))
      expect(gradient.stops[0].color).to(eq(red))
      expect(gradient.stops[1].color).to(eq(blue))
    end

    it "converts colors to HSL color space" do
      gradient = described_class.build(["#FF0000", "#0000FF"])
      expect(gradient.stops[0].color).to(be_a(Unmagic::Color::HSL))
      expect(gradient.stops[1].color).to(be_a(Unmagic::Color::HSL))
    end
  end

  describe "#initialize" do
    it "raises error if stop color is not HSL" do
      red = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      blue = Unmagic::Color::RGB.parse("#0000FF")
      stops = [
        Unmagic::Color::Gradient::Stop.new(color: red, position: 0.0),
        Unmagic::Color::Gradient::Stop.new(color: blue, position: 1.0),
      ]
      expect do
        described_class.new(stops)
      end.to(raise_error(Unmagic::Color::HSL::Gradient::Linear::Error, /must be an HSL color/))
    end
  end

  describe "#rasterize" do
    let(:direction) { Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT }

    it "generates bitmap with specified width" do
      gradient = described_class.build(["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"], direction: direction)
      bitmap = gradient.rasterize(width: 5)
      expect(bitmap.width).to(eq(5))
      expect(bitmap.height).to(eq(1))
      expect(bitmap.pixels[0].length).to(eq(5))
    end

    it "interpolates colors across the gradient" do
      gradient = described_class.build(["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"], direction: direction)
      bitmap = gradient.rasterize(width: 3)
      expect(bitmap.at(0, 0)).to(be_a(Unmagic::Color::HSL))
      expect(bitmap.at(2, 0)).to(be_a(Unmagic::Color::HSL))
    end
  end
end
