# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::OKLCH::Gradient::Linear) do
  describe ".color_class" do
    it "returns OKLCH class" do
      expect(Unmagic::Color::OKLCH::Gradient::Linear.color_class).to(eq(Unmagic::Color::OKLCH))
    end
  end

  describe ".build" do
    it "builds gradient from color strings" do
      gradient = Unmagic::Color::OKLCH::Gradient::Linear.build(["oklch(0.5 0.15 30)", "oklch(0.7 0.15 240)"])
      expect(gradient.stops.length).to(eq(2))
      expect(gradient.stops[0].color).to(be_a(Unmagic::Color::OKLCH))
      expect(gradient.stops[1].color).to(be_a(Unmagic::Color::OKLCH))
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(eq(1.0))
    end

    it "builds gradient from color objects" do
      c1 = Unmagic::Color::OKLCH.new(lightness: 0.5, chroma: 0.15, hue: 30)
      c2 = Unmagic::Color::OKLCH.new(lightness: 0.7, chroma: 0.15, hue: 240)
      gradient = Unmagic::Color::OKLCH::Gradient::Linear.build([c1, c2])
      expect(gradient.stops.length).to(eq(2))
      expect(gradient.stops[0].color).to(eq(c1))
      expect(gradient.stops[1].color).to(eq(c2))
    end
  end

  describe "#initialize" do
    it "raises error if stop color is not OKLCH" do
      c1 = Unmagic::Color::OKLCH.new(lightness: 0.5, chroma: 0.15, hue: 30)
      blue = Unmagic::Color::RGB.parse("#0000FF")
      stops = [
        Unmagic::Color::Gradient::Stop.new(color: c1, position: 0.0),
        Unmagic::Color::Gradient::Stop.new(color: blue, position: 1.0),
      ]
      expect do
        Unmagic::Color::OKLCH::Gradient::Linear.new(stops)
      end.to(raise_error(Unmagic::Color::OKLCH::Gradient::Linear::Error, /must be an OKLCH color/))
    end
  end

  describe "#rasterize" do
    let(:direction) { Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT }

    it "generates bitmap with specified width" do
      gradient = Unmagic::Color::OKLCH::Gradient::Linear.build(["oklch(0.5 0.15 30)", "oklch(0.7 0.15 240)"], direction: direction)
      bitmap = gradient.rasterize(width: 5)
      expect(bitmap.width).to(eq(5))
      expect(bitmap.height).to(eq(1))
      expect(bitmap.pixels[0].length).to(eq(5))
    end

    it "interpolates colors across the gradient" do
      gradient = Unmagic::Color::OKLCH::Gradient::Linear.build(["oklch(0.5 0.15 30)", "oklch(0.7 0.15 240)"], direction: direction)
      bitmap = gradient.rasterize(width: 3)
      expect(bitmap.at(0, 0)).to(be_a(Unmagic::Color::OKLCH))
      expect(bitmap.at(2, 0)).to(be_a(Unmagic::Color::OKLCH))
    end
  end
end
