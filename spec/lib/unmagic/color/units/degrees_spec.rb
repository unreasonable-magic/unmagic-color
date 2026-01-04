# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Units::Degrees) do
  def new(...)
    Unmagic::Color::Units::Degrees.new(...)
  end

  def build(...)
    Unmagic::Color::Units::Degrees.build(...)
  end

  def find_by_name(...)
    Unmagic::Color::Units::Degrees.find_by_name(...)
  end

  def parse(...)
    Unmagic::Color::Units::Degrees.parse(...)
  end

  describe ".build" do
    it "accepts a Degrees instance and returns it" do
      degrees = new(value: 225)
      result = build(degrees)
      expect(result).to(be(degrees))
    end

    it "accepts a numeric value" do
      degrees = build(225)
      expect(degrees).to(be_a(Unmagic::Color::Units::Degrees))
      expect(degrees.value).to(eq(225.0))
    end

    it "accepts a float value" do
      degrees = build(45.5)
      expect(degrees.value).to(eq(45.5))
    end

    it "accepts a degree string" do
      degrees = build("225deg")
      expect(degrees.value).to(eq(225.0))
    end

    it "accepts a float degree string" do
      degrees = build("45.5deg")
      expect(degrees.value).to(eq(45.5))
    end

    it "accepts a negative degree string" do
      degrees = build("-45deg")
      expect(degrees.value).to(eq(315.0))
    end

    it "accepts a plain numeric string" do
      degrees = build("225")
      expect(degrees.value).to(eq(225.0))
    end

    it "accepts named degrees" do
      expect(build("top").value).to(eq(0.0))
      expect(build("right").value).to(eq(90.0))
      expect(build("bottom").value).to(eq(180.0))
      expect(build("left").value).to(eq(270.0))
    end

    it "accepts named degrees by alias" do
      expect(build("north").value).to(eq(0.0))
      expect(build("east").value).to(eq(90.0))
      expect(build("south").value).to(eq(180.0))
      expect(build("west").value).to(eq(270.0))
    end

    it "raises error for invalid input type" do
      expect { build([]) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Expected Numeric, String, or Degrees/))
      expect { build(nil) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Expected Numeric, String, or Degrees/))
    end

    it "raises error for invalid string format" do
      expect { build("invalid") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid degrees format/))
      expect { build("abc deg") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid degrees format/))
    end
  end

  describe ".parse" do
    it "parses degree strings" do
      expect(parse("90deg").value).to(eq(90.0))
      expect(parse("45.5deg").value).to(eq(45.5))
      expect(parse("-45deg").value).to(eq(315.0))
    end

    it "parses plain numeric strings" do
      expect(parse("90").value).to(eq(90.0))
      expect(parse("45.5").value).to(eq(45.5))
      expect(parse("-45").value).to(eq(315.0))
    end

    it "parses named degrees" do
      expect(parse("top").value).to(eq(0.0))
      expect(parse("right").value).to(eq(90.0))
      expect(parse("south").value).to(eq(180.0))
    end

    it "raises error for non-string input" do
      expect { parse(90) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Input must be a string/))
    end

    it "handles whitespace" do
      expect(parse("  90deg  ").value).to(eq(90.0))
      expect(parse("  top  ").value).to(eq(0.0))
    end
  end

  describe "#initialize" do
    it "wraps values to 0-360 range" do
      expect(new(value: 360).value).to(eq(0.0))
      expect(new(value: 450).value).to(eq(90.0))
      expect(new(value: 720).value).to(eq(0.0))
    end

    it "wraps negative values" do
      expect(new(value: -45).value).to(eq(315.0))
      expect(new(value: -90).value).to(eq(270.0))
      expect(new(value: -360).value).to(eq(0.0))
    end

    it "handles zero" do
      expect(new(value: 0).value).to(eq(0.0))
    end

    it "preserves decimal values" do
      expect(new(value: 45.5).value).to(eq(45.5))
      expect(new(value: 123.456).value).to(eq(123.456))
    end
  end

  describe "#to_f" do
    it "returns the float value" do
      degrees = new(value: 225)
      expect(degrees.to_f).to(eq(225.0))
      expect(degrees.to_f).to(be_a(Float))
    end
  end

  describe "#opposite" do
    it "returns the opposite direction" do
      expect(Unmagic::Color::Units::Degrees::TOP.opposite).to(eq(Unmagic::Color::Units::Degrees::BOTTOM))
      expect(Unmagic::Color::Units::Degrees::RIGHT.opposite).to(eq(Unmagic::Color::Units::Degrees::LEFT))
      expect(Unmagic::Color::Units::Degrees::BOTTOM.opposite).to(eq(Unmagic::Color::Units::Degrees::TOP))
      expect(Unmagic::Color::Units::Degrees::LEFT.opposite).to(eq(Unmagic::Color::Units::Degrees::RIGHT))
    end

    it "returns opposite for diagonals" do
      expect(Unmagic::Color::Units::Degrees::TOP_RIGHT.opposite).to(eq(Unmagic::Color::Units::Degrees::BOTTOM_LEFT))
      expect(Unmagic::Color::Units::Degrees::BOTTOM_LEFT.opposite).to(eq(Unmagic::Color::Units::Degrees::TOP_RIGHT))
    end

    it "creates new Degrees for arbitrary values" do
      degrees = new(value: 30)
      opposite = degrees.opposite
      expect(opposite.value).to(eq(210.0))
    end
  end

  describe "#to_css" do
    it "formats as CSS degree string" do
      expect(new(value: 225).to_css).to(eq("225.0deg"))
      expect(new(value: 45.5).to_css).to(eq("45.5deg"))
      expect(new(value: 0).to_css).to(eq("0.0deg"))
    end
  end

  describe "#to_s" do
    it "returns name for named constants" do
      expect(Unmagic::Color::Units::Degrees::TOP.to_s).to(eq("top"))
      expect(Unmagic::Color::Units::Degrees::BOTTOM_LEFT.to_s).to(eq("bottom left"))
    end

    it "returns degree string with ° symbol for unnamed degrees" do
      expect(new(value: 123).to_s).to(eq("123.0°"))
      expect(new(value: 45.5).to_s).to(eq("45.5°"))
    end
  end

  describe ".parse with ° symbol" do
    it "parses degree strings with ° symbol" do
      expect(parse("90°").value).to(eq(90.0))
      expect(parse("45.5°").value).to(eq(45.5))
      expect(parse("-45°").value).to(eq(315.0))
    end

    it "handles whitespace with ° symbol" do
      expect(parse("  90°  ").value).to(eq(90.0))
    end
  end

  describe "#<=>" do
    it "compares with another Degrees instance" do
      d1 = new(value: 45)
      d2 = new(value: 90)
      d3 = new(value: 45)

      expect(d1 <=> d2).to(eq(-1))
      expect(d2 <=> d1).to(eq(1))
      expect(d1 <=> d3).to(eq(0))
    end

    it "compares with a Numeric" do
      degrees = new(value: 90)

      expect(degrees <=> 45).to(eq(1))
      expect(degrees <=> 90).to(eq(0))
      expect(degrees <=> 135).to(eq(-1))
    end

    it "returns nil for incompatible types" do
      degrees = new(value: 90)
      expect(degrees <=> "90").to(be_nil)
      expect(degrees <=> []).to(be_nil)
    end
  end

  describe "#==" do
    it "equals another Degrees with same value" do
      d1 = new(value: 225)
      d2 = new(value: 225)
      d3 = new(value: 180)

      expect(d1 == d2).to(be(true))
      expect(d1 == d3).to(be(false))
    end

    it "equals a Numeric with same value" do
      degrees = new(value: 225)

      expect(degrees == 225).to(be(true))
      expect(degrees == 225.0).to(be(true))
      expect(degrees == 180).to(be(false))
    end

    it "does not equal incompatible types" do
      degrees = new(value: 225)

      expect(degrees == "225").to(be(false))
      expect(degrees == [225]).to(be(false))
      expect(degrees.nil?).to(be(false))
    end

    it "works with wrapped values" do
      d1 = new(value: 0)
      d2 = new(value: 360)

      expect(d1 == d2).to(be(true))
    end
  end

  describe "constants" do
    it "defines TOP" do
      expect(Unmagic::Color::Units::Degrees::TOP.value).to(eq(0.0))
      expect(Unmagic::Color::Units::Degrees::TOP.name).to(eq("top"))
      expect(Unmagic::Color::Units::Degrees::TOP.aliases).to(include("north"))
    end

    it "defines RIGHT" do
      expect(Unmagic::Color::Units::Degrees::RIGHT.value).to(eq(90.0))
      expect(Unmagic::Color::Units::Degrees::RIGHT.name).to(eq("right"))
      expect(Unmagic::Color::Units::Degrees::RIGHT.aliases).to(include("east"))
    end

    it "defines BOTTOM" do
      expect(Unmagic::Color::Units::Degrees::BOTTOM.value).to(eq(180.0))
      expect(Unmagic::Color::Units::Degrees::BOTTOM.name).to(eq("bottom"))
      expect(Unmagic::Color::Units::Degrees::BOTTOM.aliases).to(include("south"))
    end

    it "defines LEFT" do
      expect(Unmagic::Color::Units::Degrees::LEFT.value).to(eq(270.0))
      expect(Unmagic::Color::Units::Degrees::LEFT.name).to(eq("left"))
      expect(Unmagic::Color::Units::Degrees::LEFT.aliases).to(include("west"))
    end
  end

  describe ".find_by_name" do
    it "finds by name" do
      expect(find_by_name("top")).to(eq(Unmagic::Color::Units::Degrees::TOP))
      expect(find_by_name("right")).to(eq(Unmagic::Color::Units::Degrees::RIGHT))
    end

    it "finds by alias" do
      expect(find_by_name("north")).to(eq(Unmagic::Color::Units::Degrees::TOP))
      expect(find_by_name("east")).to(eq(Unmagic::Color::Units::Degrees::RIGHT))
      expect(find_by_name("south")).to(eq(Unmagic::Color::Units::Degrees::BOTTOM))
      expect(find_by_name("west")).to(eq(Unmagic::Color::Units::Degrees::LEFT))
    end

    it "is case insensitive" do
      expect(find_by_name("TOP")).to(eq(Unmagic::Color::Units::Degrees::TOP))
      expect(find_by_name("North")).to(eq(Unmagic::Color::Units::Degrees::TOP))
    end

    it "returns nil for unknown names" do
      expect(find_by_name("nowhere")).to(be_nil)
    end
  end
end
