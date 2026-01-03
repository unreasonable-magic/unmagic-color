# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Units::Degrees) do
  describe ".build" do
    it "accepts a Degrees instance and returns it" do
      degrees = described_class.new(value: 225)
      result = described_class.build(degrees)
      expect(result).to(be(degrees))
    end

    it "accepts a numeric value" do
      degrees = described_class.build(225)
      expect(degrees).to(be_a(described_class))
      expect(degrees.value).to(eq(225.0))
    end

    it "accepts a float value" do
      degrees = described_class.build(45.5)
      expect(degrees.value).to(eq(45.5))
    end

    it "accepts a degree string" do
      degrees = described_class.build("225deg")
      expect(degrees.value).to(eq(225.0))
    end

    it "accepts a float degree string" do
      degrees = described_class.build("45.5deg")
      expect(degrees.value).to(eq(45.5))
    end

    it "accepts a negative degree string" do
      degrees = described_class.build("-45deg")
      expect(degrees.value).to(eq(315.0))
    end

    it "accepts a plain numeric string" do
      degrees = described_class.build("225")
      expect(degrees.value).to(eq(225.0))
    end

    it "accepts named degrees" do
      expect(described_class.build("top").value).to(eq(0.0))
      expect(described_class.build("right").value).to(eq(90.0))
      expect(described_class.build("bottom").value).to(eq(180.0))
      expect(described_class.build("left").value).to(eq(270.0))
    end

    it "accepts named degrees by alias" do
      expect(described_class.build("north").value).to(eq(0.0))
      expect(described_class.build("east").value).to(eq(90.0))
      expect(described_class.build("south").value).to(eq(180.0))
      expect(described_class.build("west").value).to(eq(270.0))
    end

    it "raises error for invalid input type" do
      expect { described_class.build([]) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Expected Numeric, String, or Degrees/))
      expect { described_class.build(nil) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Expected Numeric, String, or Degrees/))
    end

    it "raises error for invalid string format" do
      expect { described_class.build("invalid") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid degrees format/))
      expect { described_class.build("abc deg") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid degrees format/))
    end
  end

  describe ".parse" do
    it "parses degree strings" do
      expect(described_class.parse("90deg").value).to(eq(90.0))
      expect(described_class.parse("45.5deg").value).to(eq(45.5))
      expect(described_class.parse("-45deg").value).to(eq(315.0))
    end

    it "parses plain numeric strings" do
      expect(described_class.parse("90").value).to(eq(90.0))
      expect(described_class.parse("45.5").value).to(eq(45.5))
      expect(described_class.parse("-45").value).to(eq(315.0))
    end

    it "parses named degrees" do
      expect(described_class.parse("top").value).to(eq(0.0))
      expect(described_class.parse("right").value).to(eq(90.0))
      expect(described_class.parse("south").value).to(eq(180.0))
    end

    it "raises error for non-string input" do
      expect { described_class.parse(90) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Input must be a string/))
    end

    it "handles whitespace" do
      expect(described_class.parse("  90deg  ").value).to(eq(90.0))
      expect(described_class.parse("  top  ").value).to(eq(0.0))
    end
  end

  describe "#initialize" do
    it "wraps values to 0-360 range" do
      expect(described_class.new(value: 360).value).to(eq(0.0))
      expect(described_class.new(value: 450).value).to(eq(90.0))
      expect(described_class.new(value: 720).value).to(eq(0.0))
    end

    it "wraps negative values" do
      expect(described_class.new(value: -45).value).to(eq(315.0))
      expect(described_class.new(value: -90).value).to(eq(270.0))
      expect(described_class.new(value: -360).value).to(eq(0.0))
    end

    it "handles zero" do
      expect(described_class.new(value: 0).value).to(eq(0.0))
    end

    it "preserves decimal values" do
      expect(described_class.new(value: 45.5).value).to(eq(45.5))
      expect(described_class.new(value: 123.456).value).to(eq(123.456))
    end
  end

  describe "#to_f" do
    it "returns the float value" do
      degrees = described_class.new(value: 225)
      expect(degrees.to_f).to(eq(225.0))
      expect(degrees.to_f).to(be_a(Float))
    end
  end

  describe "#opposite" do
    it "returns the opposite direction" do
      expect(described_class::TOP.opposite).to(eq(described_class::BOTTOM))
      expect(described_class::RIGHT.opposite).to(eq(described_class::LEFT))
      expect(described_class::BOTTOM.opposite).to(eq(described_class::TOP))
      expect(described_class::LEFT.opposite).to(eq(described_class::RIGHT))
    end

    it "returns opposite for diagonals" do
      expect(described_class::TOP_RIGHT.opposite).to(eq(described_class::BOTTOM_LEFT))
      expect(described_class::BOTTOM_LEFT.opposite).to(eq(described_class::TOP_RIGHT))
    end

    it "creates new Degrees for arbitrary values" do
      degrees = described_class.new(value: 30)
      opposite = degrees.opposite
      expect(opposite.value).to(eq(210.0))
    end
  end

  describe "#to_css" do
    it "formats as CSS degree string" do
      expect(described_class.new(value: 225).to_css).to(eq("225.0deg"))
      expect(described_class.new(value: 45.5).to_css).to(eq("45.5deg"))
      expect(described_class.new(value: 0).to_css).to(eq("0.0deg"))
    end
  end

  describe "#to_s" do
    it "returns name for named constants" do
      expect(described_class::TOP.to_s).to(eq("top"))
      expect(described_class::BOTTOM_LEFT.to_s).to(eq("bottom left"))
    end

    it "returns degree string with ° symbol for unnamed degrees" do
      expect(described_class.new(value: 123).to_s).to(eq("123.0°"))
      expect(described_class.new(value: 45.5).to_s).to(eq("45.5°"))
    end
  end

  describe ".parse with ° symbol" do
    it "parses degree strings with ° symbol" do
      expect(described_class.parse("90°").value).to(eq(90.0))
      expect(described_class.parse("45.5°").value).to(eq(45.5))
      expect(described_class.parse("-45°").value).to(eq(315.0))
    end

    it "handles whitespace with ° symbol" do
      expect(described_class.parse("  90°  ").value).to(eq(90.0))
    end
  end

  describe "#<=>" do
    it "compares with another Degrees instance" do
      d1 = described_class.new(value: 45)
      d2 = described_class.new(value: 90)
      d3 = described_class.new(value: 45)

      expect(d1 <=> d2).to(eq(-1))
      expect(d2 <=> d1).to(eq(1))
      expect(d1 <=> d3).to(eq(0))
    end

    it "compares with a Numeric" do
      degrees = described_class.new(value: 90)

      expect(degrees <=> 45).to(eq(1))
      expect(degrees <=> 90).to(eq(0))
      expect(degrees <=> 135).to(eq(-1))
    end

    it "returns nil for incompatible types" do
      degrees = described_class.new(value: 90)
      expect(degrees <=> "90").to(be_nil)
      expect(degrees <=> []).to(be_nil)
    end
  end

  describe "#==" do
    it "equals another Degrees with same value" do
      d1 = described_class.new(value: 225)
      d2 = described_class.new(value: 225)
      d3 = described_class.new(value: 180)

      expect(d1 == d2).to(be(true))
      expect(d1 == d3).to(be(false))
    end

    it "equals a Numeric with same value" do
      degrees = described_class.new(value: 225)

      expect(degrees == 225).to(be(true))
      expect(degrees == 225.0).to(be(true))
      expect(degrees == 180).to(be(false))
    end

    it "does not equal incompatible types" do
      degrees = described_class.new(value: 225)

      expect(degrees == "225").to(be(false))
      expect(degrees == [225]).to(be(false))
      expect(degrees.nil?).to(be(false))
    end

    it "works with wrapped values" do
      d1 = described_class.new(value: 0)
      d2 = described_class.new(value: 360)

      expect(d1 == d2).to(be(true))
    end
  end

  describe "constants" do
    it "defines TOP" do
      expect(described_class::TOP.value).to(eq(0.0))
      expect(described_class::TOP.name).to(eq("top"))
      expect(described_class::TOP.aliases).to(include("north"))
    end

    it "defines RIGHT" do
      expect(described_class::RIGHT.value).to(eq(90.0))
      expect(described_class::RIGHT.name).to(eq("right"))
      expect(described_class::RIGHT.aliases).to(include("east"))
    end

    it "defines BOTTOM" do
      expect(described_class::BOTTOM.value).to(eq(180.0))
      expect(described_class::BOTTOM.name).to(eq("bottom"))
      expect(described_class::BOTTOM.aliases).to(include("south"))
    end

    it "defines LEFT" do
      expect(described_class::LEFT.value).to(eq(270.0))
      expect(described_class::LEFT.name).to(eq("left"))
      expect(described_class::LEFT.aliases).to(include("west"))
    end
  end

  describe ".find_by_name" do
    it "finds by name" do
      expect(described_class.find_by_name("top")).to(eq(described_class::TOP))
      expect(described_class.find_by_name("right")).to(eq(described_class::RIGHT))
    end

    it "finds by alias" do
      expect(described_class.find_by_name("north")).to(eq(described_class::TOP))
      expect(described_class.find_by_name("east")).to(eq(described_class::RIGHT))
      expect(described_class.find_by_name("south")).to(eq(described_class::BOTTOM))
      expect(described_class.find_by_name("west")).to(eq(described_class::LEFT))
    end

    it "is case insensitive" do
      expect(described_class.find_by_name("TOP")).to(eq(described_class::TOP))
      expect(described_class.find_by_name("North")).to(eq(described_class::TOP))
    end

    it "returns nil for unknown names" do
      expect(described_class.find_by_name("nowhere")).to(be_nil)
    end
  end
end
