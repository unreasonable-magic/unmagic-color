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

    it "accepts CSS direction keywords" do
      expect(described_class.build("to top").value).to(eq(0.0))
      expect(described_class.build("to right").value).to(eq(90.0))
      expect(described_class.build("to bottom").value).to(eq(180.0))
      expect(described_class.build("to left").value).to(eq(270.0))
    end

    it "accepts diagonal direction keywords" do
      expect(described_class.build("to top right").value).to(eq(45.0))
      expect(described_class.build("to right top").value).to(eq(45.0))
      expect(described_class.build("to bottom right").value).to(eq(135.0))
      expect(described_class.build("to right bottom").value).to(eq(135.0))
      expect(described_class.build("to bottom left").value).to(eq(225.0))
      expect(described_class.build("to left bottom").value).to(eq(225.0))
      expect(described_class.build("to top left").value).to(eq(315.0))
      expect(described_class.build("to left top").value).to(eq(315.0))
    end

    it "handles extra whitespace in direction keywords" do
      expect(described_class.build("to  top  right").value).to(eq(45.0))
      expect(described_class.build("to   bottom   left  ").value).to(eq(225.0))
    end

    it "handles uppercase and mixed case direction keywords" do
      expect(described_class.build("TO TOP").value).to(eq(0.0))
      expect(described_class.build("To Right").value).to(eq(90.0))
      expect(described_class.build("TO BOTTOM LEFT").value).to(eq(225.0))
    end

    it "raises error for invalid input type" do
      expect { described_class.build([]) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Expected Numeric, String, or Degrees/))
      expect { described_class.build(nil) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Expected Numeric, String, or Degrees/))
    end

    it "raises error for invalid string format" do
      expect { described_class.build("invalid") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid degrees format/))
      expect { described_class.build("abc deg") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid degrees format/))
    end

    it "raises error for invalid direction" do
      expect { described_class.build("to nowhere") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid direction/))
      expect { described_class.build("to top bottom") }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Invalid direction/))
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

    it "parses direction keywords" do
      expect(described_class.parse("to right").value).to(eq(90.0))
      expect(described_class.parse("to left top").value).to(eq(315.0))
    end

    it "raises error for non-string input" do
      expect { described_class.parse(90) }.to(raise_error(Unmagic::Color::Units::Degrees::ParseError, /Input must be a string/))
    end

    it "handles whitespace" do
      expect(described_class.parse("  90deg  ").value).to(eq(90.0))
      expect(described_class.parse("  to right  ").value).to(eq(90.0))
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

  describe "#to_s" do
    it "formats as degree string" do
      expect(described_class.new(value: 225).to_s).to(eq("225.0deg"))
      expect(described_class.new(value: 45.5).to_s).to(eq("45.5deg"))
      expect(described_class.new(value: 0).to_s).to(eq("0.0deg"))
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

  describe "integration with build" do
    it "produces identical instances from different input formats" do
      d1 = described_class.build(225)
      d2 = described_class.build("225deg")
      d3 = described_class.build("to left bottom")

      expect(d1 == d2).to(be(true))
      expect(d2 == d3).to(be(true))
      expect(d1.value).to(eq(225.0))
      expect(d2.value).to(eq(225.0))
      expect(d3.value).to(eq(225.0))
    end

    it "handles all cardinal directions" do
      directions = {
        "to top" => 0,
        "to right" => 90,
        "to bottom" => 180,
        "to left" => 270,
      }

      directions.each do |keyword, degrees|
        expect(described_class.build(keyword).value).to(eq(degrees.to_f))
        expect(described_class.build(degrees).value).to(eq(degrees.to_f))
        expect(described_class.build("#{degrees}deg").value).to(eq(degrees.to_f))
      end
    end

    it "handles all diagonal directions" do
      diagonals = {
        "to top right" => 45,
        "to right top" => 45,
        "to bottom right" => 135,
        "to right bottom" => 135,
        "to bottom left" => 225,
        "to left bottom" => 225,
        "to top left" => 315,
        "to left top" => 315,
      }

      diagonals.each do |keyword, degrees|
        expect(described_class.build(keyword).value).to(eq(degrees.to_f))
      end
    end
  end
end
