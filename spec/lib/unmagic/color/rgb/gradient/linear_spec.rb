# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::RGB::Gradient::Linear) do
  describe ".color_class" do
    it "returns RGB class" do
      expect(described_class.color_class).to(eq(Unmagic::Color::RGB))
    end
  end

  describe ".build" do
    it "builds gradient from color strings" do
      gradient = described_class.build(["#FF0000", "#0000FF"])
      expect(gradient.stops.length).to(eq(2))
      expect(gradient.stops[0].color.to_hex).to(eq("#ff0000"))
      expect(gradient.stops[1].color.to_hex).to(eq("#0000ff"))
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(eq(1.0))
    end

    it "builds gradient from color objects" do
      red = Unmagic::Color::RGB.parse("#FF0000")
      blue = Unmagic::Color::RGB.parse("#0000FF")
      gradient = described_class.build([red, blue])
      expect(gradient.stops.length).to(eq(2))
      expect(gradient.stops[0].color).to(eq(red))
      expect(gradient.stops[1].color).to(eq(blue))
    end

    it "auto-balances positions for three colors" do
      gradient = described_class.build(["#FF0000", "#00FF00", "#0000FF"])
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(eq(0.5))
      expect(gradient.stops[2].position).to(eq(1.0))
    end

    it "accepts explicit positions" do
      gradient = described_class.build([["#FF0000", 0.0], ["#00FF00", 0.3], ["#0000FF", 1.0]])
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(eq(0.3))
      expect(gradient.stops[2].position).to(eq(1.0))
    end

    it "accepts mixed positioned and non-positioned colors" do
      gradient = described_class.build(["#FF0000", ["#00FF00", 0.3], "#0000FF"])
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(eq(0.3))
      expect(gradient.stops[2].position).to(eq(1.0))
    end

    it "converts colors to RGB color space" do
      gradient = described_class.build(["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"])
      expect(gradient.stops[0].color).to(be_a(Unmagic::Color::RGB))
      expect(gradient.stops[1].color).to(be_a(Unmagic::Color::RGB))
    end
  end

  describe "#initialize" do
    it "accepts stops array" do
      red = Unmagic::Color::RGB.parse("#FF0000")
      blue = Unmagic::Color::RGB.parse("#0000FF")
      stops = [
        Unmagic::Color::Gradient::Stop.new(color: red, position: 0.0),
        Unmagic::Color::Gradient::Stop.new(color: blue, position: 1.0),
      ]
      gradient = described_class.new(stops)
      expect(gradient.stops).to(eq(stops))
    end

    it "raises error if fewer than 2 stops" do
      red = Unmagic::Color::RGB.parse("#FF0000")
      stops = [Unmagic::Color::Gradient::Stop.new(color: red, position: 0.0)]
      expect do
        described_class.new(stops)
      end.to(raise_error(Unmagic::Color::Gradient::Base::Error, /must have at least 2 stops/))
    end

    it "raises error if stop color is not RGB" do
      red = Unmagic::Color::RGB.parse("#FF0000")
      blue = Unmagic::Color::HSL.parse("hsl(240, 100%, 50%)")
      stops = [
        Unmagic::Color::Gradient::Stop.new(color: red, position: 0.0),
        Unmagic::Color::Gradient::Stop.new(color: blue, position: 1.0),
      ]
      expect do
        described_class.new(stops)
      end.to(raise_error(Unmagic::Color::RGB::Gradient::Linear::Error, /must be an RGB color/))
    end

    it "raises error if stops are not sorted by position" do
      red = Unmagic::Color::RGB.parse("#FF0000")
      blue = Unmagic::Color::RGB.parse("#0000FF")
      stops = [
        Unmagic::Color::Gradient::Stop.new(color: red, position: 1.0),
        Unmagic::Color::Gradient::Stop.new(color: blue, position: 0.0),
      ]
      expect do
        described_class.new(stops)
      end.to(raise_error(Unmagic::Color::Gradient::Base::Error, /must be sorted by position/))
    end
  end

  describe "#rasterize" do
    let(:direction) { Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT }

    it "generates bitmap with specified width" do
      gradient = described_class.build(["#FF0000", "#0000FF"], direction: direction)
      bitmap = gradient.rasterize(width: 5)
      expect(bitmap.width).to(eq(5))
      expect(bitmap.height).to(eq(1))
      expect(bitmap.pixels[0].length).to(eq(5))
    end

    it "interpolates colors across the gradient" do
      gradient = described_class.build(["#FF0000", "#0000FF"], direction: direction)
      bitmap = gradient.rasterize(width: 3)
      expect(bitmap.at(0, 0).to_hex).to(eq("#ff0000"))
      expect(bitmap.at(2, 0).to_hex).to(eq("#0000ff"))
    end

    it "raises error if width is less than 1" do
      gradient = described_class.build(["#FF0000", "#0000FF"], direction: direction)
      expect do
        gradient.rasterize(width: 0)
      end.to(raise_error(Unmagic::Color::RGB::Gradient::Linear::Error, /width must be at least 1/))
    end

    it "raises error if height is less than 1" do
      gradient = described_class.build(["#FF0000", "#0000FF"], direction: direction)
      expect do
        gradient.rasterize(height: 0)
      end.to(raise_error(Unmagic::Color::RGB::Gradient::Linear::Error, /height must be at least 1/))
    end

    it "generates 2D bitmap with width and height" do
      gradient = described_class.build(["#FF0000", "#0000FF"], direction: direction)
      bitmap = gradient.rasterize(width: 3, height: 2)
      expect(bitmap.width).to(eq(3))
      expect(bitmap.height).to(eq(2))
      expect(bitmap.pixels.length).to(eq(2))
      expect(bitmap.pixels[0].length).to(eq(3))
      expect(bitmap.pixels[1].length).to(eq(3))
    end
  end
end
