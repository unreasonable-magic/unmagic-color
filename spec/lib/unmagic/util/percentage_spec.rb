# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Util::Percentage) do
  def parse(...)
    Unmagic::Util::Percentage.parse(...)
  end

  def new(...)
    Unmagic::Util::Percentage.new(...)
  end

  def build(...)
    Unmagic::Util::Percentage.build(...)
  end

  describe ".parse" do
    context "with explicit percentage format" do
      it "parses percentage strings" do
        percentage = parse("50%")
        expect(percentage.value).to(eq(50.0))
      end

      it "parses decimal percentages" do
        percentage = parse("23.5%")
        expect(percentage.value).to(eq(23.5))
      end

      it "clamps to valid range" do
        percentage = parse("150%")
        expect(percentage.value).to(eq(100.0))
      end
    end

    context "with bare decimal values" do
      it "treats values ≤ 1.0 as ratios" do
        percentage = parse("0.5")
        expect(percentage.value).to(eq(50.0))
      end

      it "treats 1.0 as ratio" do
        percentage = parse("1.0")
        expect(percentage.value).to(eq(100.0))
      end

      it "treats 0.0 as ratio" do
        percentage = parse("0.0")
        expect(percentage.value).to(eq(0.0))
      end

      it "treats values > 1.0 as literal percentages" do
        percentage = parse("75")
        expect(percentage.value).to(eq(75.0))
      end

      it "treats 100 as literal percentage" do
        percentage = parse("100")
        expect(percentage.value).to(eq(100.0))
      end
    end

    context "with fraction notation" do
      it "parses simple fractions" do
        percentage = parse("1/2")
        expect(percentage.value).to(eq(50.0))
      end

      it "parses quarter fraction" do
        percentage = parse("1/4")
        expect(percentage.value).to(eq(25.0))
      end

      it "parses three quarters" do
        percentage = parse("3/4")
        expect(percentage.value).to(eq(75.0))
      end

      it "parses decimal fractions" do
        percentage = parse("10/100")
        expect(percentage.value).to(eq(10.0))
      end

      it "handles division by zero" do
        percentage = parse("1/0")
        expect(percentage.value).to(eq(0.0))
      end

      it "handles fractions with spaces" do
        percentage = parse("1 / 2")
        expect(percentage.value).to(eq(50.0))
      end
    end

    context "with whitespace" do
      it "strips leading whitespace" do
        percentage = parse("  50%")
        expect(percentage.value).to(eq(50.0))
      end

      it "strips trailing whitespace" do
        percentage = parse("50%  ")
        expect(percentage.value).to(eq(50.0))
      end

      it "strips surrounding whitespace" do
        percentage = parse("  0.5  ")
        expect(percentage.value).to(eq(50.0))
      end
    end

    context "with invalid input" do
      it "raises ArgumentError for non-string input" do
        expect { parse(50) }.to(raise_error(ArgumentError, "Input must be a string"))
      end

      it "raises ArgumentError for nil input" do
        expect { parse(nil) }.to(raise_error(ArgumentError, "Input must be a string"))
      end

      it "raises ArgumentError for invalid fraction format" do
        expect { parse("1/2/3") }.to(raise_error(ArgumentError, "Invalid fraction format"))
      end
    end
  end

  describe "#initialize" do
    it "creates percentage from value keyword argument" do
      percentage = new(value: 75.5)
      expect(percentage.value).to(eq(75.5))
    end

    it "clamps values to 0-100 range" do
      expect(new(value: 150).value).to(eq(100.0))
      expect(new(value: -10).value).to(eq(0.0))
    end
  end

  describe ".build" do
    it "creates percentage from single value" do
      percentage = build(75.5)
      expect(percentage.value).to(eq(75.5))
    end

    it "creates percentage from numerator and denominator" do
      percentage = build(50, 100)
      expect(percentage.value).to(eq(50.0))
    end

    it "handles division by zero in ratio mode" do
      percentage = build(1, 0)
      expect(percentage.value).to(eq(0.0))
    end

    it "accepts keyword arguments" do
      percentage = build(value: 75.5)
      expect(percentage.value).to(eq(75.5))
    end

    it "returns input if already a Percentage instance" do
      original = new(value: 50)
      result = build(original)
      expect(result).to(be(original))
    end

    it "returns nil when passed nil" do
      result = build(nil)
      expect(result).to(be_nil)
    end

    it "creates percentage from Rational" do
      percentage = build(Rational(1, 2))
      expect(percentage.value).to(eq(50.0))
    end

    it "creates percentage from Rational literal" do
      percentage = build(10r / 100)
      expect(percentage.value).to(eq(10.0))
    end

    it "creates percentage from Rational quarters" do
      percentage = build(Rational(3, 4))
      expect(percentage.value).to(eq(75.0))
    end

    it "treats float values <= 1.0 as ratios" do
      percentage = build(0.5)
      expect(percentage.value).to(eq(50.0))
    end

    it "treats 1.0 as ratio" do
      percentage = build(1.0)
      expect(percentage.value).to(eq(100.0))
    end

    it "treats 0.0 as ratio" do
      percentage = build(0.0)
      expect(percentage.value).to(eq(0.0))
    end

    it "treats values > 1.0 as literal percentages" do
      percentage = build(75)
      expect(percentage.value).to(eq(75.0))
    end

    it "treats 100 as literal percentage" do
      percentage = build(100)
      expect(percentage.value).to(eq(100.0))
    end
  end

  describe "#to_s" do
    it "formats with default decimal places" do
      percentage = new(value: 75.5)
      expect(percentage.to_s).to(eq("75.5%"))
    end

    it "formats with custom decimal places" do
      percentage = new(value: 75.567)
      expect(percentage.to_s(decimal_places: 2)).to(eq("75.57%"))
    end
  end

  describe "#to_ratio" do
    it "converts to ratio form" do
      percentage = new(value: 50)
      expect(percentage.to_ratio).to(eq(0.5))
    end

    it "converts 100% to 1.0" do
      percentage = new(value: 100)
      expect(percentage.to_ratio).to(eq(1.0))
    end

    it "converts 0% to 0.0" do
      percentage = new(value: 0)
      expect(percentage.to_ratio).to(eq(0.0))
    end
  end
end
