# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Gradient::Base) do
  let(:gradient_class) { Unmagic::Color::RGB::Gradient::Linear }

  describe ".build" do
    it "auto-balances four colors evenly" do
      gradient = gradient_class.build(["#FF0000", "#00FF00", "#0000FF", "#FFFF00"])
      expect(gradient.stops[0].position).to(be_within(0.001).of(0.0))
      expect(gradient.stops[1].position).to(be_within(0.001).of(0.333))
      expect(gradient.stops[2].position).to(be_within(0.001).of(0.666))
      expect(gradient.stops[3].position).to(be_within(0.001).of(1.0))
    end

    it "auto-balances middle colors between positioned ones" do
      gradient = gradient_class.build([["#FF0000", 0.0], "#00FF00", "#0000FF", ["#FFFF00", 1.0]])
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(be_within(0.001).of(0.333))
      expect(gradient.stops[2].position).to(be_within(0.001).of(0.666))
      expect(gradient.stops[3].position).to(eq(1.0))
    end

    it "auto-balances multiple groups independently" do
      gradient = gradient_class.build([["#FF0000", 0.0], "#00FF00", ["#0000FF", 0.5], "#FFFF00", ["#FF00FF", 1.0]])
      expect(gradient.stops[0].position).to(eq(0.0))
      expect(gradient.stops[1].position).to(eq(0.25))
      expect(gradient.stops[2].position).to(eq(0.5))
      expect(gradient.stops[3].position).to(eq(0.75))
      expect(gradient.stops[4].position).to(eq(1.0))
    end
  end

  describe "#initialize" do
    it "accepts stops with direction" do
      red = Unmagic::Color::RGB.parse("#FF0000")
      blue = Unmagic::Color::RGB.parse("#0000FF")
      stops = [
        Unmagic::Color::Gradient::Stop.new(color: red, position: 0.0),
        Unmagic::Color::Gradient::Stop.new(color: blue, position: 1.0),
      ]
      direction = Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT
      gradient = gradient_class.new(stops, direction: direction)
      expect(gradient.direction).to(eq(direction))
    end

    it "raises error if stops is not an array" do
      expect do
        gradient_class.new("not an array")
      end.to(raise_error(Unmagic::Color::Gradient::Base::Error, /stops must be an array/))
    end

    it "raises error if stop is not a Stop object" do
      red = Unmagic::Color::RGB.parse("#FF0000")
      expect do
        gradient_class.new([red, red])
      end.to(raise_error(Unmagic::Color::Gradient::Base::Error, /must be a Stop object/))
    end
  end
end
