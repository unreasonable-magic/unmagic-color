# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color) do
  describe ".parse" do
    it "parses hex colors with hash" do
      color = described_class.parse("#FF0000")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses hex colors without hash" do
      color = described_class.parse("FF0000")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses 3-character hex codes" do
      color = described_class.parse("#F00")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses RGB format with parentheses" do
      color = described_class.parse("rgb(255, 128, 0)")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(0))
    end

    it "parses HSL format" do
      color = described_class.parse("hsl(0, 100%, 50%)")
      expect(color).to(be_a(Unmagic::Color::HSL))
      rgb = color.to_rgb
      expect(rgb.red).to(eq(255))
      expect(rgb.green).to(eq(0))
      expect(rgb.blue).to(eq(0))
    end

    it "returns existing color instance unchanged" do
      original = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      parsed = described_class.parse(original)
      expect(parsed).to(be(original))
    end

    it "raises ParseError for nil input" do
      expect { described_class.parse(nil) }.to(raise_error(Unmagic::Color::ParseError, "Can't pass nil as a color"))
    end

    it "raises ParseError for empty string" do
      expect { described_class.parse("") }.to(raise_error(Unmagic::Color::ParseError, "Can't parse empty string"))
      expect { described_class.parse("   ") }.to(raise_error(Unmagic::Color::ParseError, "Can't parse empty string"))
    end

    it "raises ParseError for unknown color format" do
      expect { described_class.parse("invalid") }.to(raise_error(Unmagic::Color::ParseError, 'Unknown color "invalid"'))
      expect { described_class.parse("rainbow") }.to(raise_error(Unmagic::Color::ParseError, 'Unknown color "rainbow"'))
    end

    it "lets RGB parsing errors bubble up" do
      expect { described_class.parse("rgb(255)") }.to(raise_error(Unmagic::Color::RGB::ParseError, /Expected 3 RGB values, got 1/))
      expect { described_class.parse("rgb(255, abc, 0)") }.to(raise_error(Unmagic::Color::RGB::ParseError, /Invalid green value: "abc"/))
    end

    it "lets hex parsing errors bubble up" do
      expect { described_class.parse("#FFFF") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid number of characters/))
      expect { described_class.parse("#GGGGGG") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid hex characters: G/))
    end

    it "lets HSL parsing errors bubble up" do
      expect { described_class.parse("hsl(180, 50%)") }.to(raise_error(Unmagic::Color::HSL::ParseError, /Expected 3 HSL values, got 2/))
      expect { described_class.parse("hsl(abc, 50%, 50%)") }.to(raise_error(Unmagic::Color::HSL::ParseError, /Invalid hue value: "abc"/))
      expect { described_class.parse("hsl(180, 150%, 50%)") }.to(raise_error(Unmagic::Color::HSL::ParseError, /Saturation must be between 0 and 100, got 150/))
    end

    it "lets OKLCH parsing errors bubble up" do
      expect { described_class.parse("oklch(0.5 0.2)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError, /Expected 3 OKLCH values, got 2/))
      expect { described_class.parse("oklch(abc 0.2 180)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError, /Invalid lightness value: "abc"/))
      expect { described_class.parse("oklch(1.5 0.2 180)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError, /Lightness must be between 0 and 1, got 1.5/))
    end

    it "handles whitespace around valid colors" do
      color = described_class.parse("  #FF0000  ")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end
  end

  describe ".[]" do
    it "works as alias for parse" do
      color = described_class["#FF0000"]
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "returns existing color instance unchanged" do
      original = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      result = described_class[original]
      expect(result).to(be(original))
    end

    it "raises ParseError for invalid input" do
      expect { described_class["invalid"] }.to(raise_error(Unmagic::Color::ParseError))
    end
  end
end
