# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Gradient::Stop) do
  def new(...)
    Unmagic::Color::Gradient::Stop.new(...)
  end

  describe "#initialize" do
    it "accepts a color and position" do
      color = Unmagic::Color::RGB.parse("#FF0000")
      stop = new(color: color, position: 0.5)
      expect(stop.color).to(eq(color))
      expect(stop.position).to(eq(0.5))
    end

    it "converts position to float" do
      color = Unmagic::Color::RGB.parse("#FF0000")
      stop = new(color: color, position: 1)
      expect(stop.position).to(eq(1.0))
      expect(stop.position).to(be_a(Float))
    end

    it "accepts position 0.0" do
      color = Unmagic::Color::RGB.parse("#FF0000")
      stop = new(color: color, position: 0.0)
      expect(stop.position).to(eq(0.0))
    end

    it "accepts position 1.0" do
      color = Unmagic::Color::RGB.parse("#FF0000")
      stop = new(color: color, position: 1.0)
      expect(stop.position).to(eq(1.0))
    end

    it "raises error if color is not a Color instance" do
      expect do
        new(color: "#FF0000", position: 0.5)
      end.to(raise_error(ArgumentError, /color must be a Color instance/))
    end

    it "raises error if position is less than 0.0" do
      color = Unmagic::Color::RGB.parse("#FF0000")
      expect do
        new(color: color, position: -0.1)
      end.to(raise_error(ArgumentError, /position must be between 0.0 and 1.0/))
    end

    it "raises error if position is greater than 1.0" do
      color = Unmagic::Color::RGB.parse("#FF0000")
      expect do
        new(color: color, position: 1.1)
      end.to(raise_error(ArgumentError, /position must be between 0.0 and 1.0/))
    end
  end
end
