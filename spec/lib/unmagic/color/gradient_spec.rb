# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Gradient) do
  describe ".linear" do
    it "detects RGB color space from hex colors" do
      gradient = described_class.linear(["#FF0000", "#0000FF"])
      expect(gradient).to(be_a(Unmagic::Color::RGB::Gradient::Linear))
    end

    it "detects HSL color space from hsl() strings" do
      gradient = described_class.linear(["hsl(0, 100%, 50%)", "hsl(240, 100%, 50%)"])
      expect(gradient).to(be_a(Unmagic::Color::HSL::Gradient::Linear))
    end

    it "detects OKLCH color space from oklch() strings" do
      gradient = described_class.linear(["oklch(0.5 0.15 30)", "oklch(0.7 0.15 240)"])
      expect(gradient).to(be_a(Unmagic::Color::OKLCH::Gradient::Linear))
    end

    it "detects color space from color objects" do
      rgb = Unmagic::Color::RGB.parse("#FF0000")
      gradient = described_class.linear([rgb, "#0000FF"])
      expect(gradient).to(be_a(Unmagic::Color::RGB::Gradient::Linear))
    end

    it "detects color space from positioned colors" do
      gradient = described_class.linear([["hsl(0, 100%, 50%)", 0.0], ["hsl(240, 100%, 50%)", 1.0]])
      expect(gradient).to(be_a(Unmagic::Color::HSL::Gradient::Linear))
    end

    it "accepts direction as string" do
      gradient = described_class.linear(["#FF0000", "#0000FF"], direction: "to right")
      expect(gradient.direction.to.name).to(eq("right"))
    end

    it "accepts direction as numeric degrees" do
      gradient = described_class.linear(["#FF0000", "#0000FF"], direction: 45)
      expect(gradient.direction.to.value).to(eq(45.0))
    end

    it "accepts direction as Degrees instance" do
      degrees = Unmagic::Color::Units::Degrees.new(value: 90)
      gradient = described_class.linear(["#FF0000", "#0000FF"], direction: degrees)
      expect(gradient.direction.to.value).to(eq(90.0))
    end

    it "accepts direction as Direction instance" do
      direction = Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT
      gradient = described_class.linear(["#FF0000", "#0000FF"], direction: direction)
      expect(gradient.direction).to(eq(direction))
    end

    it "defaults to 'to bottom' direction when omitted" do
      gradient = described_class.linear(["#FF0000", "#0000FF"])
      expect(gradient.direction).to(eq(Unmagic::Color::Units::Degrees::Direction::TOP_TO_BOTTOM))
    end

    it "raises error for empty colors array" do
      expect do
        described_class.linear([])
      end.to(raise_error(Unmagic::Color::Gradient::Error, /must have at least one color/))
    end

    it "raises error for invalid direction type" do
      expect do
        described_class.linear(["#FF0000", "#0000FF"], direction: [])
      end.to(raise_error(Unmagic::Color::Gradient::Error, /Invalid direction type/))
    end
  end
end
