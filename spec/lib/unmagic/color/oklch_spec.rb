# frozen_string_literal: true

require "spec_helper"
require "pp"
require "stringio"

RSpec.describe(Unmagic::Color::OKLCH) do
  def parse(...)
    Unmagic::Color::OKLCH.parse(...)
  end

  def new(...)
    Unmagic::Color::OKLCH.new(...)
  end

  def derive(...)
    Unmagic::Color::OKLCH.derive(...)
  end

  describe ".parse" do
    it "parses OKLCH with parentheses" do
      color = parse("oklch(0.58 0.15 180)")
      expect(color).to(be_a(Unmagic::Color::OKLCH))
      expect(color.lightness).to(be_within(0.01).of(0.58))
      expect(color.chroma).to(be_within(0.01).of(0.15))
      expect(color.hue).to(be_within(0.1).of(180))
    end

    it "parses OKLCH without parentheses" do
      color = parse("0.58 0.15 180")
      expect(color).to(be_a(Unmagic::Color::OKLCH))
      expect(color.lightness).to(be_within(0.01).of(0.58))
      expect(color.chroma).to(be_within(0.01).of(0.15))
      expect(color.hue).to(be_within(0.1).of(180))
    end

    it "parses OKLCH with decimal values" do
      color = parse("oklch(0.75 0.25 45.5)")
      expect(color.lightness).to(be_within(0.01).of(0.75))
      expect(color.chroma).to(be_within(0.01).of(0.25))
      expect(color.hue).to(be_within(0.1).of(45.5))
    end

    it "handles edge cases" do
      color = parse("oklch(0.0 0.0 0)")
      expect(color.lightness).to(eq(0.0))
      expect(color.chroma).to(eq(0.0))
      expect(color.hue).to(eq(0.0))
    end

    it "raises ParseError for invalid input" do
      expect { parse("oklch(0.58 0.15)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError))
      expect { parse("oklch(invalid input)") }.to(raise_error(Unmagic::Color::OKLCH::ParseError))
      expect { parse("") }.to(raise_error(Unmagic::Color::OKLCH::ParseError))
      expect { parse(nil) }.to(raise_error(Unmagic::Color::OKLCH::ParseError))
      expect { parse(123) }.to(raise_error(Unmagic::Color::OKLCH::ParseError))
    end
  end

  describe ".derive" do
    it "generates consistent colors from integer seeds" do
      color1 = derive(12345)
      color2 = derive(12345)
      expect(color1.lightness).to(eq(color2.lightness))
      expect(color1.chroma).to(eq(color2.chroma))
      expect(color1.hue).to(eq(color2.hue))
    end

    it "generates different colors for different seeds" do
      color1 = derive(12345)
      color2 = derive(54321)
      expect(color1).not_to(eq(color2))
    end

    it "respects custom parameters" do
      color = derive(12345, lightness: 0.7, chroma_range: (0.20..0.30))
      expect(color.lightness).to(eq(0.7))
      expect(color.chroma).to(be_between(0.20, 0.30))
    end

    it "raises error for non-integer seeds" do
      expect { derive("not_integer") }.to(raise_error(ArgumentError, "Seed must be an integer"))
      expect { derive(3.14) }.to(raise_error(ArgumentError, "Seed must be an integer"))
    end
  end

  describe "#new" do
    it "creates OKLCH with valid values" do
      color = new(lightness: 0.58, chroma: 0.15, hue: 180)
      expect(color.lightness).to(eq(0.58))
      expect(color.chroma).to(eq(0.15))
      expect(color.hue).to(eq(180))
    end

    it "clamps lightness to 0-1" do
      color = new(lightness: 1.5, chroma: 0.15, hue: 180)
      expect(color.lightness).to(eq(1.0))

      color = new(lightness: -0.5, chroma: 0.15, hue: 180)
      expect(color.lightness).to(eq(0.0))
    end

    it "clamps chroma to 0-0.5" do
      color = new(lightness: 0.58, chroma: 0.8, hue: 180)
      expect(color.chroma).to(eq(0.5))

      color = new(lightness: 0.58, chroma: -0.1, hue: 180)
      expect(color.chroma).to(eq(0.0))
    end

    it "normalizes hue to 0-360" do
      color = new(lightness: 0.58, chroma: 0.15, hue: 450)
      expect(color.hue).to(eq(90))

      color = new(lightness: 0.58, chroma: 0.15, hue: -90)
      expect(color.hue).to(eq(270))
    end
  end

  describe "#to_oklch" do
    it "returns self" do
      color = new(lightness: 0.58, chroma: 0.15, hue: 180)
      expect(color.to_oklch).to(be(color))
    end
  end

  describe "#to_rgb" do
    it "converts to RGB instance" do
      color = new(lightness: 0.58, chroma: 0.15, hue: 180)
      rgb = color.to_rgb
      expect(rgb).to(be_a(Unmagic::Color::RGB))
    end
  end

  describe "#to_hex" do
    it "converts to hex via RGB" do
      color = new(lightness: 0.58, chroma: 0.15, hue: 180)
      hex = color.to_hex
      expect(hex).to(match(/\A#[0-9a-f]{6}\z/))
    end

    it "returns consistent hex strings" do
      color = new(lightness: 0.50, chroma: 0.10, hue: 0)
      expect(color.to_hex).to(eq(color.to_rgb.to_hex))
    end
  end

  describe "color manipulation methods" do
    let(:color) { new(lightness: 0.58, chroma: 0.15, hue: 180) }

    describe "#lighten" do
      it "increases lightness" do
        lighter = color.lighten(0.1)
        expect(lighter.lightness).to(be > color.lightness)
        expect(lighter.chroma).to(eq(color.chroma))
        expect(lighter.hue).to(eq(color.hue))
      end

      it "clamps lightness at 1.0" do
        bright = new(lightness: 0.95, chroma: 0.15, hue: 180)
        brighter = bright.lighten(0.1)
        expect(brighter.lightness).to(eq(1.0))
      end
    end

    describe "#darken" do
      it "decreases lightness" do
        darker = color.darken(0.1)
        expect(darker.lightness).to(be < color.lightness)
        expect(darker.chroma).to(eq(color.chroma))
        expect(darker.hue).to(eq(color.hue))
      end

      it "clamps lightness at 0.0" do
        dark = new(lightness: 0.05, chroma: 0.15, hue: 180)
        darker = dark.darken(0.1)
        expect(darker.lightness).to(eq(0.0))
      end
    end

    describe "#saturate" do
      it "increases chroma" do
        saturated = color.saturate(0.05)
        expect(saturated.chroma).to(be > color.chroma)
        expect(saturated.lightness).to(eq(color.lightness))
        expect(saturated.hue).to(eq(color.hue))
      end
    end

    describe "#desaturate" do
      it "decreases chroma" do
        desaturated = color.desaturate(0.05)
        expect(desaturated.chroma).to(be < color.chroma)
        expect(desaturated.lightness).to(eq(color.lightness))
        expect(desaturated.hue).to(eq(color.hue))
      end
    end

    describe "#rotate" do
      it "changes hue" do
        rotated = color.rotate(45)
        expect(rotated.hue).to(eq(225))
        expect(rotated.lightness).to(eq(color.lightness))
        expect(rotated.chroma).to(eq(color.chroma))
      end

      it "wraps hue around 360" do
        rotated = color.rotate(200) # 180 + 200 = 380, should become 20
        expect(rotated.hue).to(eq(20))
      end
    end
  end

  describe "#light? and #dark?" do
    it "identifies light colors" do
      light_color = new(lightness: 0.8, chroma: 0.15, hue: 180)
      expect(light_color).to(be_light)
      expect(light_color).not_to(be_dark)
    end

    it "identifies dark colors" do
      dark_color = new(lightness: 0.3, chroma: 0.15, hue: 180)
      expect(dark_color).to(be_dark)
      expect(dark_color).not_to(be_light)
    end
  end

  describe "CSS output methods" do
    let(:color) { new(lightness: 0.58, chroma: 0.15, hue: 180) }

    describe "#to_css_oklch" do
      it "outputs CSS oklch format" do
        css = color.to_css_oklch
        expect(css).to(match(/^oklch\(\d+\.\d+ \d+\.\d+ \d+\.\d+\)$/))
        expect(css).to(include("0.5800", "0.1500", "180.00"))
      end
    end

    describe "#to_css_vars" do
      it "outputs CSS variables" do
        vars = color.to_css_vars
        expect(vars).to(include("--ul:0.5800"))
        expect(vars).to(include("--uc:0.1500"))
        expect(vars).to(include("--uh:180.00"))
      end
    end

    describe "#to_css_color_mix" do
      it "outputs CSS color-mix string" do
        mix = color.to_css_color_mix
        expect(mix).to(include("color-mix(in oklch"))
        expect(mix).to(include("oklch(0.5800 0.1500 180.00)"))
        expect(mix).to(include("72%"))
        expect(mix).to(include("var(--bg)"))
        expect(mix).to(include("28%"))
      end
    end
  end

  describe "#to_s" do
    it "returns CSS oklch format" do
      color = new(lightness: 0.58, chroma: 0.15, hue: 180)
      expect(color.to_s).to(eq(color.to_css_oklch))
    end
  end

  describe "#==" do
    it "compares OKLCH values with tolerance" do
      color1 = new(lightness: 0.58, chroma: 0.15, hue: 180)
      color2 = new(lightness: 0.58, chroma: 0.15, hue: 180)
      color3 = new(lightness: 0.60, chroma: 0.15, hue: 180)

      expect(color1).to(eq(color2))
      expect(color1).not_to(eq(color3))
    end
  end

  describe "#to_ansi" do
    it "delegates to RGB#to_ansi" do
      # This will convert to approximately red
      color = new(lightness: 0.60, chroma: 0.25, hue: 30)
      result = color.to_ansi
      expect(result).to(match(/\A(?:3[0-7]|38;2;\d+;\d+;\d+)\z/))
    end

    it "supports background layer" do
      color = new(lightness: 0.60, chroma: 0.25, hue: 30)
      result = color.to_ansi(layer: :background)
      expect(result).to(match(/\A(?:4[0-7]|48;2;\d+;\d+;\d+)\z/))
    end
  end

  describe "alpha channel support" do
    describe "initialization" do
      it "defaults alpha to 100 (fully opaque)" do
        oklch = new(lightness: 0.65, chroma: 0.15, hue: 240)
        expect(oklch.alpha.value).to(eq(100.0))
      end

      it "accepts explicit alpha value" do
        oklch = new(lightness: 0.65, chroma: 0.15, hue: 240, alpha: 50)
        expect(oklch.alpha.value).to(eq(50.0))
      end
    end

    describe "parsing with alpha" do
      it "parses oklch(L C H / alpha) format" do
        oklch = parse("oklch(0.65 0.15 240 / 0.5)")
        expect(oklch.lightness).to(be_within(0.001).of(0.65))
        expect(oklch.chroma.value).to(be_within(0.001).of(0.15))
        expect(oklch.hue.value).to(eq(240))
        expect(oklch.alpha.value).to(eq(50.0))
      end

      it "parses oklch(L C H / percentage) format" do
        oklch = parse("oklch(0.65 0.15 240 / 50%)")
        expect(oklch.alpha.value).to(eq(50.0))
      end
    end

    describe "output with alpha" do
      describe "#to_css_oklch" do
        it "includes alpha when alpha < 100" do
          oklch = new(lightness: 0.65, chroma: 0.15, hue: 240, alpha: 50)
          expect(oklch.to_css_oklch).to(include("/ 0.5"))
        end

        it "omits alpha when alpha = 100" do
          oklch = new(lightness: 0.65, chroma: 0.15, hue: 240, alpha: 100)
          expect(oklch.to_css_oklch).not_to(include("/"))
        end

        it "omits alpha when alpha is default" do
          oklch = new(lightness: 0.65, chroma: 0.15, hue: 240)
          expect(oklch.to_css_oklch).not_to(include("/"))
        end
      end

      describe "#to_s" do
        it "returns css_oklch format with alpha" do
          oklch = new(lightness: 0.65, chroma: 0.15, hue: 240, alpha: 75)
          expect(oklch.to_s).to(eq(oklch.to_css_oklch))
        end
      end
    end

    describe "blending with alpha" do
      it "interpolates alpha values" do
        oklch1 = new(lightness: 0.65, chroma: 0.15, hue: 30, alpha: 100)
        oklch2 = new(lightness: 0.65, chroma: 0.15, hue: 240, alpha: 0)
        blended = oklch1.blend(oklch2, 0.5)
        expect(blended.alpha.value).to(eq(50.0))
      end

      it "blends colors with different alpha" do
        oklch1 = new(lightness: 0.65, chroma: 0.15, hue: 30, alpha: 80)
        oklch2 = new(lightness: 0.65, chroma: 0.15, hue: 120, alpha: 20)
        blended = oklch1.blend(oklch2, 0.25)
        expect(blended.alpha.value).to(eq(65.0))
      end
    end

    describe "conversions preserve alpha" do
      it "preserves alpha when converting to RGB" do
        oklch = new(lightness: 0.65, chroma: 0.15, hue: 240, alpha: 50)
        rgb = oklch.to_rgb
        expect(rgb.alpha.value).to(eq(50.0))
      end

      it "preserves alpha through OKLCH→RGB→OKLCH conversion" do
        oklch1 = new(lightness: 0.65, chroma: 0.15, hue: 240, alpha: 60)
        rgb = oklch1.to_rgb
        oklch2 = rgb.to_oklch
        expect(oklch2.alpha.value).to(eq(60.0))
      end
    end
  end

  describe "#pretty_print" do
    it "outputs standard Ruby format with colored swatch in class name" do
      oklch = new(lightness: 0.60, chroma: 0.15, hue: 240)
      io = StringIO.new
      PP.pp(oklch, io)

      output = io.string.chomp
      expect(output).to(include("\x1b["))
      expect(output).to(include("█"))
      expect(output).to(include("#<Unmagic::Color::OKLCH["))
      expect(output).to(include("@chroma=0.15"))
      expect(output).to(include("@hue=240"))
    end

    it "formats chroma with 2 decimal places and rounds hue" do
      oklch = new(lightness: 0.654321, chroma: 0.156789, hue: 45.7)
      io = StringIO.new
      PP.pp(oklch, io)

      output = io.string.chomp
      expect(output).to(include("@chroma=0.16"))
      expect(output).to(include("@hue=46"))
    end
  end
end
