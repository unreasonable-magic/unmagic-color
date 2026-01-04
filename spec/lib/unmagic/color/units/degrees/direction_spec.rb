# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Units::Degrees::Direction) do
  def matches?(...)
    Unmagic::Color::Units::Degrees::Direction.matches?(...)
  end

  def new(...)
    Unmagic::Color::Units::Degrees::Direction.new(...)
  end

  describe ".matches?" do
    it "matches 'to X' patterns" do
      expect(matches?("to top")).to(be(true))
      expect(matches?("to right")).to(be(true))
      expect(matches?("to bottom left")).to(be(true))
      expect(matches?("to  top  right  ")).to(be(true))
    end

    it "matches 'from X to Y' patterns" do
      expect(matches?("from left to right")).to(be(true))
      expect(matches?("from bottom left to top right")).to(be(true))
      expect(matches?("FROM TOP TO BOTTOM")).to(be(true))
    end

    it "matches 'X to Y' patterns without 'from'" do
      expect(matches?("left to right")).to(be(true))
      expect(matches?("bottom to top")).to(be(true))
      expect(matches?("top left to bottom right")).to(be(true))
    end

    it "matches 'from X' patterns" do
      expect(matches?("from left")).to(be(true))
      expect(matches?("from top")).to(be(true))
    end

    it "does not match numeric degrees" do
      expect(matches?("45deg")).to(be(false))
      expect(matches?("90")).to(be(false))
      expect(matches?("-45deg")).to(be(false))
    end

    it "does not match color values" do
      expect(matches?("#ff0000")).to(be(false))
      expect(matches?("rgb(255, 0, 0)")).to(be(false))
      expect(matches?("red")).to(be(false))
    end

    it "matches any 'X to Y' patterns" do
      expect(matches?("red to blue")).to(be(true))
      expect(matches?("foo to bar")).to(be(true))
    end

    it "returns false for non-strings" do
      expect(matches?(45)).to(be(false))
      expect(matches?(nil)).to(be(false))
      expect(matches?([])).to(be(false))
    end
  end

  describe ".build" do
    it "returns existing Direction instance" do
      direction = new(from: Unmagic::Color::Units::Degrees::LEFT, to: Unmagic::Color::Units::Degrees::RIGHT)
      result = Unmagic::Color::Units::Degrees::Direction.build(direction)
      expect(result).to(be(direction))
    end

    it "builds from hash with string values" do
      direction = Unmagic::Color::Units::Degrees::Direction.build(from: "north", to: "south")
      expect(direction.from.name).to(eq("top"))
      expect(direction.to.name).to(eq("bottom"))
    end

    it "builds from hash with mixed values" do
      direction = Unmagic::Color::Units::Degrees::Direction.build(from: "45deg", to: "top right")
      expect(direction.from.value).to(eq(45.0))
      expect(direction.to.name).to(eq("top right"))
    end

    it "builds from direction string" do
      direction = Unmagic::Color::Units::Degrees::Direction.build("from left to right")
      expect(direction.from.name).to(eq("left"))
      expect(direction.to.name).to(eq("right"))
    end

    it "raises error for hash without :from key" do
      expect do
        Unmagic::Color::Units::Degrees::Direction.build(to: "south")
      end.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /must have :from and :to keys/))
    end

    it "raises error for hash without :to key" do
      expect do
        Unmagic::Color::Units::Degrees::Direction.build(from: "north")
      end.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /must have :from and :to keys/))
    end
  end

  describe ".parse" do
    it "parses 'to X' patterns" do
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to top").to.name).to(eq("top"))
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to right").to.name).to(eq("right"))
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to bottom").to.name).to(eq("bottom"))
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to left").to.name).to(eq("left"))
    end

    it "parses 'from X to Y' patterns" do
      direction = Unmagic::Color::Units::Degrees::Direction.parse("from left to right")
      expect(direction.from.name).to(eq("left"))
      expect(direction.to.name).to(eq("right"))

      direction = Unmagic::Color::Units::Degrees::Direction.parse("from bottom to top")
      expect(direction.from.name).to(eq("bottom"))
      expect(direction.to.name).to(eq("top"))

      direction = Unmagic::Color::Units::Degrees::Direction.parse("from bottom left to top right")
      expect(direction.from.name).to(eq("bottom left"))
      expect(direction.to.name).to(eq("top right"))
    end

    it "parses 'X to Y' patterns without 'from'" do
      direction = Unmagic::Color::Units::Degrees::Direction.parse("left to right")
      expect(direction.from.name).to(eq("left"))
      expect(direction.to.name).to(eq("right"))

      direction = Unmagic::Color::Units::Degrees::Direction.parse("bottom to top")
      expect(direction.from.name).to(eq("bottom"))
      expect(direction.to.name).to(eq("top"))

      direction = Unmagic::Color::Units::Degrees::Direction.parse("bottom left to top right")
      expect(direction.from.name).to(eq("bottom left"))
      expect(direction.to.name).to(eq("top right"))
    end

    it "parses diagonal directions" do
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to top right").to.name).to(eq("top right"))
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to bottom right").to.name).to(eq("bottom right"))
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to bottom left").to.name).to(eq("bottom left"))
      expect(Unmagic::Color::Units::Degrees::Direction.parse("to top left").to.name).to(eq("top left"))
    end

    it "raises error for invalid directions" do
      expect do
        Unmagic::Color::Units::Degrees::Direction.parse("to nowhere")
      end.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid degrees format/))
    end
  end

  describe "#to_css" do
    it "converts to CSS direction string" do
      direction = new(from: Unmagic::Color::Units::Degrees::LEFT, to: Unmagic::Color::Units::Degrees::RIGHT)
      expect(direction.to_css).to(eq("from left to right"))

      direction = new(from: Unmagic::Color::Units::Degrees::BOTTOM_LEFT, to: Unmagic::Color::Units::Degrees::TOP_RIGHT)
      expect(direction.to_css).to(eq("from bottom left to top right"))
    end

    it "works with unnamed degrees" do
      direction = new(
        from: Unmagic::Color::Units::Degrees.new(value: 30),
        to: Unmagic::Color::Units::Degrees.new(value: 120),
      )
      expect(direction.to_css).to(eq("from 30.0deg to 120.0deg"))
    end
  end

  describe "#to_s" do
    it "returns canonical string format" do
      direction = new(from: Unmagic::Color::Units::Degrees::LEFT, to: Unmagic::Color::Units::Degrees::RIGHT)
      expect(direction.to_s).to(eq("from left to right"))

      direction = new(from: Unmagic::Color::Units::Degrees::BOTTOM_LEFT, to: Unmagic::Color::Units::Degrees::TOP_RIGHT)
      expect(direction.to_s).to(eq("from bottom left to top right"))
    end

    it "works with unnamed degrees" do
      direction = new(
        from: Unmagic::Color::Units::Degrees.new(value: 30),
        to: Unmagic::Color::Units::Degrees.new(value: 120),
      )
      expect(direction.to_s).to(eq("from 30.0° to 120.0°"))
    end
  end

  describe "parsing with ° symbol" do
    it "parses directions with ° symbol" do
      direction = Unmagic::Color::Units::Degrees::Direction.parse("from 30° to 120°")
      expect(direction.from.value).to(eq(30.0))
      expect(direction.to.value).to(eq(120.0))
    end

    it "parses mixed formats with ° symbol" do
      direction = Unmagic::Color::Units::Degrees::Direction.parse("from 45° to top right")
      expect(direction.from.value).to(eq(45.0))
      expect(direction.to.name).to(eq("top right"))
    end
  end

  describe "#==" do
    it "compares by from and to" do
      d1 = new(from: Unmagic::Color::Units::Degrees::LEFT, to: Unmagic::Color::Units::Degrees::RIGHT)
      d2 = new(from: Unmagic::Color::Units::Degrees::LEFT, to: Unmagic::Color::Units::Degrees::RIGHT)
      d3 = new(from: Unmagic::Color::Units::Degrees::TOP, to: Unmagic::Color::Units::Degrees::BOTTOM)

      expect(d1 == d2).to(be(true))
      expect(d1 == d3).to(be(false))
    end
  end

  describe "constants" do
    it "defines BOTTOM_TO_TOP" do
      expect(Unmagic::Color::Units::Degrees::Direction::BOTTOM_TO_TOP.from).to(eq(Unmagic::Color::Units::Degrees::BOTTOM))
      expect(Unmagic::Color::Units::Degrees::Direction::BOTTOM_TO_TOP.to).to(eq(Unmagic::Color::Units::Degrees::TOP))
    end

    it "defines LEFT_TO_RIGHT" do
      expect(Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT.from).to(eq(Unmagic::Color::Units::Degrees::LEFT))
      expect(Unmagic::Color::Units::Degrees::Direction::LEFT_TO_RIGHT.to).to(eq(Unmagic::Color::Units::Degrees::RIGHT))
    end
  end
end
