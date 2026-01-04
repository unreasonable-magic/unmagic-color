# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color) do
  def parse(...)
    Unmagic::Color.parse(...)
  end

  describe ".parse" do
    it "parses hex colors with hash" do
      color = parse("#FF0000")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses hex colors without hash" do
      color = parse("FF0000")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses 3-character hex codes" do
      color = parse("#F00")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses RGB format with parentheses" do
      color = parse("rgb(255, 128, 0)")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(0))
    end

    it "parses HSL format" do
      color = parse("hsl(0, 100%, 50%)")
      expect(color).to(be_a(Unmagic::Color::HSL))
      rgb = color.to_rgb
      expect(rgb.red).to(eq(255))
      expect(rgb.green).to(eq(0))
      expect(rgb.blue).to(eq(0))
    end

    it "returns existing color instance unchanged" do
      original = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      parsed = parse(original)
      expect(parsed).to(be(original))
    end

    it "raises ParseError for nil input" do
      expect { parse(nil) }.to(raise_error(Unmagic::Color::ParseError, "Can't pass nil as a color"))
    end

    it "raises ParseError for empty string" do
      expect { parse("") }.to(raise_error(Unmagic::Color::ParseError, "Can't parse empty string"))
      expect { parse("   ") }.to(raise_error(Unmagic::Color::ParseError, "Can't parse empty string"))
    end

    it "raises ParseError for unknown color format" do
      expect { parse("invalid") }.to(raise_error(Unmagic::Color::ParseError, 'Unknown color "invalid"'))
      expect { parse("rainbow") }.to(raise_error(Unmagic::Color::ParseError, 'Unknown color "rainbow"'))
    end

    it "lets RGB parsing errors bubble up" do
      expect { parse("rgb(255)") }.to(raise_error(Unmagic::Color::RGB::ParseError, /Expected 3 or 4 RGB values, got 1/))
      expect { parse("rgb(255, abc, 0)") }.to(raise_error(Unmagic::Color::RGB::ParseError, /Invalid green value: "abc"/))
    end

    it "lets hex parsing errors bubble up" do
      expect { parse("#FFFFF") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid number of characters/))
      expect { parse("#GGGGGG") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid hex characters: G/))
    end

    it "lets HSL parsing errors bubble up" do
      expect { parse("hsl(180, 50%)") }.to(raise_error(Unmagic::Color::HSL::ParseError, /Expected 3 or 4 HSL values, got 2/))
      expect { parse("hsl(abc, 50%, 50%)") }.to(raise_error(Unmagic::Color::HSL::ParseError, /Invalid hue value: "abc"/))
      expect { parse("hsl(180, 150%, 50%)") }.to(raise_error(Unmagic::Color::HSL::ParseError, /Saturation must be between 0 and 100, got 150/))
    end

    it "lets OKLCH parsing errors bubble up" do
      expect { parse("oklch(0.5 0.2)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError, /Expected 3 OKLCH values, got 2/))
      expect { parse("oklch(abc 0.2 180)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError, /Invalid lightness value: "abc"/))
      expect { parse("oklch(1.5 0.2 180)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError, /Lightness must be between 0 and 1, got 1.5/))
    end

    it "handles whitespace around valid colors" do
      color = parse("  #FF0000  ")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end
  end

  describe ".[]" do
    it "works as alias for parse" do
      color = Unmagic::Color["#FF0000"]
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "returns existing color instance unchanged" do
      original = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      result = Unmagic::Color[original]
      expect(result).to(be(original))
    end

    it "raises ParseError for invalid input" do
      expect { Unmagic::Color["invalid"] }.to(raise_error(Unmagic::Color::ParseError))
    end
  end

  describe "Alpha" do
    describe "#to_css" do
      it "formats fully opaque as '1'" do
        alpha = Unmagic::Color::Alpha.new(100)
        expect(alpha.to_css).to(eq("1"))
      end

      it "formats fully transparent as '0'" do
        alpha = Unmagic::Color::Alpha.new(0)
        expect(alpha.to_css).to(eq("0"))
      end

      it "formats semi-transparent as decimal ratio" do
        alpha = Unmagic::Color::Alpha.new(50)
        expect(alpha.to_css).to(eq("0.5"))
      end

      it "formats 75% as '0.75'" do
        alpha = Unmagic::Color::Alpha.new(75)
        expect(alpha.to_css).to(eq("0.75"))
      end

      it "strips trailing zeros" do
        alpha = Unmagic::Color::Alpha.new(25)
        expect(alpha.to_css).to(eq("0.25"))
      end
    end

    describe ".parse" do
      it "parses CSS ratio format (inherited from Percentage)" do
        alpha = Unmagic::Color::Alpha.parse("0.5")
        expect(alpha.value).to(eq(50.0))
        expect(alpha).to(be_a(Unmagic::Color::Alpha))
      end

      it "parses percentage format" do
        alpha = Unmagic::Color::Alpha.parse("50%")
        expect(alpha.value).to(eq(50.0))
        expect(alpha).to(be_a(Unmagic::Color::Alpha))
      end

      it "parses fraction format" do
        alpha = Unmagic::Color::Alpha.parse("1/2")
        expect(alpha.value).to(eq(50.0))
        expect(alpha).to(be_a(Unmagic::Color::Alpha))
      end
    end
  end

  describe ".parse with alpha" do
    context "with rgba format" do
      it "parses legacy rgba comma-separated format" do
        color = parse("rgba(255, 0, 0, 0.5)")
        expect(color).to(be_a(Unmagic::Color::RGB))
        expect(color.red.value).to(eq(255))
        expect(color.green.value).to(eq(0))
        expect(color.blue.value).to(eq(0))
        expect(color.alpha.value).to(eq(50.0))
      end

      it "parses modern rgb with slash separator" do
        color = parse("rgb(255 0 0 / 0.5)")
        expect(color).to(be_a(Unmagic::Color::RGB))
        expect(color.red.value).to(eq(255))
        expect(color.green.value).to(eq(0))
        expect(color.blue.value).to(eq(0))
        expect(color.alpha.value).to(eq(50.0))
      end
    end

    context "with hex alpha" do
      it "parses 8-digit hex with alpha" do
        color = parse("#ff000080")
        expect(color).to(be_a(Unmagic::Color::RGB))
        expect(color.red.value).to(eq(255))
        expect(color.green.value).to(eq(0))
        expect(color.blue.value).to(eq(0))
        expect(color.alpha.value).to(eq(50.2))
      end
    end

    context "with hsla format" do
      it "parses legacy hsla comma-separated format" do
        color = parse("hsla(0, 100%, 50%, 0.5)")
        expect(color).to(be_a(Unmagic::Color::HSL))
        expect(color.hue.value).to(eq(0))
        expect(color.saturation.value).to(eq(100.0))
        expect(color.lightness.value).to(eq(50.0))
        expect(color.alpha.value).to(eq(50.0))
      end

      it "parses modern hsl with slash separator" do
        color = parse("hsl(0 100% 50% / 0.5)")
        expect(color).to(be_a(Unmagic::Color::HSL))
        expect(color.alpha.value).to(eq(50.0))
      end
    end

    context "with oklch alpha" do
      it "parses oklch with slash separator" do
        color = parse("oklch(0.65 0.15 30 / 0.5)")
        expect(color).to(be_a(Unmagic::Color::OKLCH))
        expect(color.lightness).to(be_within(0.001).of(0.65))
        expect(color.chroma.value).to(be_within(0.001).of(0.15))
        expect(color.hue.value).to(eq(30))
        expect(color.alpha.value).to(eq(50.0))
      end
    end
  end
end
