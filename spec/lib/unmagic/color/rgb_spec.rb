# frozen_string_literal: true

require "spec_helper"
require "pp"
require "stringio"

RSpec.describe(Unmagic::Color::RGB) do
  def parse(...)
    Unmagic::Color::RGB.parse(...)
  end

  def new(...)
    Unmagic::Color::RGB.new(...)
  end

  def build(...)
    Unmagic::Color::RGB.build(...)
  end

  def derive(...)
    Unmagic::Color::RGB.derive(...)
  end

  describe ".parse" do
    it "raises ParseError for invalid RGB values" do
      expect { parse("rgb(255)") }.to(raise_error(Unmagic::Color::RGB::ParseError, "Expected 3 RGB values, got 1"))
      expect { parse("rgb(255, abc, 0)") }.to(raise_error(Unmagic::Color::RGB::ParseError, 'Invalid green value: "abc" (must be a number)'))
      expect { parse("rgb(255, 128, def)") }.to(raise_error(Unmagic::Color::RGB::ParseError, 'Invalid blue value: "def" (must be a number)'))
    end

    it "raises ParseError for non-string input" do
      expect { parse(123) }.to(raise_error(Unmagic::Color::RGB::ParseError, "Input must be a string"))
      expect { parse(nil) }.to(raise_error(Unmagic::Color::RGB::ParseError, "Input must be a string"))
    end

    it "lets hex parsing errors bubble up" do
      expect { parse("#FFFF") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid number of characters/))
    end

    it "parses RGB with parentheses" do
      color = parse("rgb(255, 128, 64)")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(64))
    end

    it "parses RGB without parentheses" do
      color = parse("255, 128, 64")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(64))
    end

    it "parses RGB with extra spaces" do
      color = parse("rgb(  255  ,  128  ,  64  )")
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(64))
    end

    it "parses RGB with no spaces" do
      color = parse("rgb(255,128,64)")
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(64))
    end

    it "clamps values outside 0-255" do
      color = parse("rgb(300, -50, 128)")
      expect(color.red).to(eq(255)) # Clamped to 255
      expect(color.green).to(eq(0)) # Clamped to 0
      expect(color.blue).to(eq(128))
    end

    it "parses 6-character hex with hash" do
      color = parse("#FF8040")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(64))
    end

    it "parses 6-character hex without hash" do
      color = parse("FF8040")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(128))
      expect(color.blue).to(eq(64))
    end

    it "parses 3-character hex codes" do
      color = parse("#F84")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(136))
      expect(color.blue).to(eq(68))
    end

    it "parses 3-character hex without hash" do
      color = parse("F84")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(136))
      expect(color.blue).to(eq(68))
    end

    it "handles lowercase hex" do
      color = parse("#aabbcc")
      expect(color.red).to(eq(170))
      expect(color.green).to(eq(187))
      expect(color.blue).to(eq(204))
    end

    it "handles mixed case hex" do
      color = parse("#AaBbCc")
      expect(color.red).to(eq(170))
      expect(color.green).to(eq(187))
      expect(color.blue).to(eq(204))
    end

    it "handles whitespace in hex" do
      color = parse("  #FF0000  ")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "raises ParseError for invalid input" do
      expect { parse("rgb(255, 128)") }.to(raise_error(Unmagic::Color::RGB::ParseError))
      expect { parse("rgb(red, green, blue)") }.to(raise_error(Unmagic::Color::RGB::ParseError))
      expect { parse("255 128 0") }.to(raise_error(Unmagic::Color::RGB::ParseError))
      expect { parse("#GGGGGG") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError))
      expect { parse("#FF00") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError))
      expect { parse("FFFFF") }.to(raise_error(Unmagic::Color::RGB::Hex::ParseError)) # 5 chars
      expect { parse("") }.to(raise_error(Unmagic::Color::RGB::ParseError))
      expect { parse(nil) }.to(raise_error(Unmagic::Color::RGB::ParseError))
      expect { parse(123) }.to(raise_error(Unmagic::Color::RGB::ParseError))
    end
  end

  describe ".derive" do
    it "generates consistent colors from integer seeds" do
      color1 = derive(12345)
      color2 = derive(12345)
      expect(color1.red).to(eq(color2.red))
      expect(color1.green).to(eq(color2.green))
      expect(color1.blue).to(eq(color2.blue))
    end

    it "generates different colors for different seeds" do
      color1 = derive(12345)
      color2 = derive(54321)
      expect(color1).not_to(eq(color2))
    end

    it "respects custom parameters" do
      color = derive(12345, brightness: 100, saturation: 0.3)
      # With lower saturation, RGB values should be closer to each other
      expect(color.red).to(be_between(0, 255))
      expect(color.green).to(be_between(0, 255))
      expect(color.blue).to(be_between(0, 255))
    end

    it "raises error for non-integer seeds" do
      expect { derive("not_integer") }.to(raise_error(ArgumentError, "Seed must be an integer"))
      expect { derive(3.14) }.to(raise_error(ArgumentError, "Seed must be an integer"))
    end
  end

  describe "#new" do
    it "creates RGB color with keyword arguments" do
      color = new(red: 100, green: 150, blue: 200)
      expect(color.red).to(eq(100))
      expect(color.green).to(eq(150))
      expect(color.blue).to(eq(200))
    end

    it "clamps values to 0-255" do
      color = new(red: -50, green: 300, blue: 1000)
      expect(color.red).to(eq(0))
      expect(color.green).to(eq(255))
      expect(color.blue).to(eq(255))
    end
  end

  describe "#to_hex" do
    it "converts to lowercase hex string" do
      color = new(red: 255, green: 128, blue: 64)
      expect(color.to_hex).to(eq("#ff8040"))
    end

    it "pads with zeros" do
      color = new(red: 1, green: 2, blue: 3)
      expect(color.to_hex).to(eq("#010203"))
    end
  end

  describe "#to_rgb" do
    it "returns an RGB instance" do
      color = new(red: 100, green: 150, blue: 200)
      rgb = color.to_rgb
      expect(rgb).to(be_a(Unmagic::Color::RGB))
      expect(rgb.red).to(eq(100))
      expect(rgb.green).to(eq(150))
      expect(rgb.blue).to(eq(200))
    end
  end

  describe "#to_hsl" do
    it "converts red to HSL" do
      color = new(red: 255, green: 0, blue: 0)
      hsl = color.to_hsl
      expect(hsl).to(be_a(Unmagic::Color::HSL))
      expect(hsl.hue).to(eq(0))
      expect(hsl.saturation).to(eq(100))
      expect(hsl.lightness).to(eq(50))
    end

    it "converts gray to HSL" do
      color = new(red: 128, green: 128, blue: 128)
      hsl = color.to_hsl
      expect(hsl.hue).to(eq(0))
      expect(hsl.saturation).to(eq(0))
      expect(hsl.lightness).to(eq(50))
    end
  end

  describe "#luminance" do
    it "calculates luminance for white" do
      color = new(red: 255, green: 255, blue: 255)
      expect(color.luminance).to(be_within(0.001).of(1.0))
    end

    it "calculates luminance for black" do
      color = new(red: 0, green: 0, blue: 0)
      expect(color.luminance).to(be_within(0.001).of(0.0))
    end

    it "calculates luminance for mid-gray" do
      color = new(red: 128, green: 128, blue: 128)
      expect(color.luminance).to(be_within(0.01).of(0.216))
    end
  end

  describe "#light? and #dark?" do
    it "identifies light colors" do
      color = new(red: 255, green: 255, blue: 200)
      expect(color.light?).to(be(true))
      expect(color.dark?).to(be(false))
    end

    it "identifies dark colors" do
      color = new(red: 50, green: 50, blue: 50)
      expect(color.light?).to(be(false))
      expect(color.dark?).to(be(true))
    end
  end

  describe "#blend" do
    it "blends two colors equally" do
      red = new(red: 255, green: 0, blue: 0)
      blue = new(red: 0, green: 0, blue: 255)
      purple = red.blend(blue, 0.5)
      expect(purple.red).to(eq(128))
      expect(purple.green).to(eq(0))
      expect(purple.blue).to(eq(128))
    end

    it "returns first color with 0 amount" do
      red = new(red: 255, green: 0, blue: 0)
      blue = new(red: 0, green: 0, blue: 255)
      result = red.blend(blue, 0)
      expect(result.to_hex).to(eq("#ff0000"))
    end

    it "returns second color with 1 amount" do
      red = new(red: 255, green: 0, blue: 0)
      blue = new(red: 0, green: 0, blue: 255)
      result = red.blend(blue, 1)
      expect(result.to_hex).to(eq("#0000ff"))
    end
  end

  describe "#lighten" do
    it "lightens a color" do
      color = new(red: 100, green: 100, blue: 100)
      lighter = color.lighten(0.2)
      expect(lighter.red).to(be > 100)
      expect(lighter.green).to(be > 100)
      expect(lighter.blue).to(be > 100)
    end

    it "doesn't exceed 255" do
      color = new(red: 250, green: 250, blue: 250)
      lighter = color.lighten(0.5)
      expect(lighter.red).to(eq(253))
      expect(lighter.green).to(eq(253))
      expect(lighter.blue).to(eq(253))
    end
  end

  describe "#darken" do
    it "darkens a color" do
      color = new(red: 200, green: 200, blue: 200)
      darker = color.darken(0.2)
      expect(darker.red).to(be < 200)
      expect(darker.green).to(be < 200)
      expect(darker.blue).to(be < 200)
    end

    it "doesn't go below 0" do
      color = new(red: 10, green: 10, blue: 10)
      darker = color.darken(0.9)
      expect(darker.red).to(be >= 0)
      expect(darker.green).to(be >= 0)
      expect(darker.blue).to(be >= 0)
    end
  end

  describe "#==" do
    it "compares colors by RGB values" do
      color1 = new(red: 100, green: 150, blue: 200)
      color2 = new(red: 100, green: 150, blue: 200)
      color3 = new(red: 100, green: 150, blue: 201)

      expect(color1).to(eq(color2))
      expect(color1).not_to(eq(color3))
    end

    it "returns false for non-Color objects" do
      color = new(red: 100, green: 150, blue: 200)
      expect(color).not_to(eq("#6496c8"))
      expect(color).not_to(be_nil)
      expect(color).not_to(eq([100, 150, 200]))
    end
  end

  describe "#to_s" do
    it "returns hex representation" do
      color = new(red: 255, green: 128, blue: 0)
      expect(color.to_s).to(eq("#ff8000"))
    end
  end

  describe "value clamping" do
    it "clamps values above 255" do
      color = new(red: 300, green: 500, blue: 1000)
      expect(color.red).to(eq(255))
      expect(color.green).to(eq(255))
      expect(color.blue).to(eq(255))
    end

    it "clamps negative values to 0" do
      color = new(red: -10, green: -50, blue: -100)
      expect(color.red).to(eq(0))
      expect(color.green).to(eq(0))
      expect(color.blue).to(eq(0))
    end

    it "converts string values" do
      color = new(red: "100", green: "150", blue: "200")
      expect(color.red).to(eq(100))
      expect(color.green).to(eq(150))
      expect(color.blue).to(eq(200))
    end
  end

  describe "#to_ansi" do
    context "with default (truecolor) mode" do
      it "returns 24-bit true color for non-standard colors" do
        result = new(red: 100, green: 150, blue: 200).to_ansi
        expect(result).to(eq("38;2;100;150;200"))
      end

      it "returns background true color with layer: :background" do
        result = new(red: 100, green: 150, blue: 200).to_ansi(layer: :background)
        expect(result).to(eq("48;2;100;150;200"))
      end

      it "uses true color for colors close to but not exactly ANSI colors" do
        # Almost red, but not exactly
        result = new(red: 254, green: 0, blue: 0).to_ansi
        expect(result).to(eq("38;2;254;0;0"))
      end
    end

    context "with mode: :truecolor" do
      it "returns 24-bit true color for all colors" do
        expect(new(red: 255, green: 0, blue: 0).to_ansi(mode: :truecolor)).to(eq("38;2;255;0;0"))
        expect(new(red: 0, green: 0, blue: 0).to_ansi(mode: :truecolor)).to(eq("38;2;0;0;0"))
      end

      it "returns 24-bit true color for custom colors" do
        result = new(red: 100, green: 150, blue: 200).to_ansi(mode: :truecolor)
        expect(result).to(eq("38;2;100;150;200"))
      end

      it "works with background layer" do
        result = new(red: 100, green: 150, blue: 200).to_ansi(mode: :truecolor, layer: :background)
        expect(result).to(eq("48;2;100;150;200"))
      end
    end

    context "with mode: :palette256" do
      it "converts to 256-color palette for foreground" do
        result = new(red: 100, green: 150, blue: 200).to_ansi(mode: :palette256)
        expect(result).to(match(/^38;5;\d+$/))
      end

      it "converts to 256-color palette for background" do
        result = new(red: 100, green: 150, blue: 200).to_ansi(mode: :palette256, layer: :background)
        expect(result).to(match(/^48;5;\d+$/))
      end

      it "maps standard colors to RGB cube" do
        red = new(red: 255, green: 0, blue: 0).to_ansi(mode: :palette256)
        expect(red).to(eq("38;5;196"))
      end

      it "maps grayscale colors to grayscale ramp" do
        gray = new(red: 128, green: 128, blue: 128).to_ansi(mode: :palette256)
        expect(gray).to(match(/^38;5;(232|233|234|235|236|237|238|239|240|241|242|243|244|245)$/))
      end

      it "maps RGB cube colors correctly" do
        color = new(red: 95, green: 135, blue: 175).to_ansi(mode: :palette256)
        expect(color).to(eq("38;5;67"))
      end
    end

    context "with mode: :palette16" do
      it "converts to 16-color palette codes for foreground" do
        result = new(red: 100, green: 150, blue: 200).to_ansi(mode: :palette16)
        expect(result).to(match(/^9[0-7]$/))
      end

      it "converts to 16-color palette codes for background" do
        result = new(red: 100, green: 150, blue: 200).to_ansi(mode: :palette16, layer: :background)
        expect(result).to(match(/^10[0-7]$/))
      end

      it "maps to nearest palette color" do
        red = new(red: 255, green: 0, blue: 0).to_ansi(mode: :palette16)
        expect(red).to(eq("91"))

        green = new(red: 0, green: 255, blue: 0).to_ansi(mode: :palette16)
        expect(green).to(eq("92"))

        blue = new(red: 0, green: 0, blue: 255).to_ansi(mode: :palette16)
        expect(blue).to(eq("94"))
      end

      it "finds nearest color for custom RGB" do
        color = new(red: 100, green: 150, blue: 200).to_ansi(mode: :palette16)
        expect(color).to(eq("96"))
      end

      it "maps black correctly" do
        black = new(red: 0, green: 0, blue: 0).to_ansi(mode: :palette16)
        expect(black).to(eq("90"))
      end

      it "maps white correctly" do
        white = new(red: 255, green: 255, blue: 255).to_ansi(mode: :palette16)
        expect(white).to(eq("97"))
      end
    end

    context "with error handling" do
      it "raises ArgumentError for invalid layer" do
        color = new(red: 255, green: 0, blue: 0)
        expect do
          color.to_ansi(layer: :invalid)
        end.to(raise_error(ArgumentError, /layer must be :foreground or :background/))
      end

      it "raises ArgumentError for invalid mode" do
        color = new(red: 255, green: 0, blue: 0)
        expect do
          color.to_ansi(mode: :invalid)
        end.to(raise_error(ArgumentError, /mode must be :truecolor, :palette256, or :palette16/))
      end
    end

    context "with integration with parsed colors" do
      it "works with hex-parsed colors" do
        color = Unmagic::Color.parse("#ff0000")
        expect(color.to_ansi).to(eq("38;2;255;0;0"))
      end

      it "works with named colors" do
        color = Unmagic::Color.parse("red")
        expect(color.to_ansi).to(eq("38;2;255;0;0"))
      end

      it "works with ANSI-parsed colors" do
        color = Unmagic::Color.parse("31")
        expect(color.to_ansi).to(eq("38;2;255;0;0"))
      end
    end
  end

  describe ".build" do
    describe "with integer argument" do
      it "creates RGB from hexadecimal or decimal integer" do
        # Test hexadecimal notation
        color = build(0xDAA520)
        expect(color.red.value).to(eq(218))
        expect(color.green.value).to(eq(165))
        expect(color.blue.value).to(eq(32))

        # Test decimal notation (same value)
        color = build(14329120)
        expect(color.red.value).to(eq(218))
        expect(color.green.value).to(eq(165))
        expect(color.blue.value).to(eq(32))
      end

      it "handles black (0)" do
        color = build(0)
        expect(color.red.value).to(eq(0))
        expect(color.green.value).to(eq(0))
        expect(color.blue.value).to(eq(0))
      end

      it "handles white (0xFFFFFF)" do
        color = build(0xFFFFFF)
        expect(color.red.value).to(eq(255))
        expect(color.green.value).to(eq(255))
        expect(color.blue.value).to(eq(255))
      end

      it "handles red (0xFF0000)" do
        color = build(0xFF0000)
        expect(color.red.value).to(eq(255))
        expect(color.green.value).to(eq(0))
        expect(color.blue.value).to(eq(0))
      end

      it "handles green (0x00FF00)" do
        color = build(0x00FF00)
        expect(color.red.value).to(eq(0))
        expect(color.green.value).to(eq(255))
        expect(color.blue.value).to(eq(0))
      end

      it "handles blue (0x0000FF)" do
        color = build(0x0000FF)
        expect(color.red.value).to(eq(0))
        expect(color.green.value).to(eq(0))
        expect(color.blue.value).to(eq(255))
      end
    end

    describe "with string argument" do
      it "delegates to parse" do
        color = build("#DAA520")
        expect(color.red.value).to(eq(218))
        expect(color.green.value).to(eq(165))
        expect(color.blue.value).to(eq(32))
      end
    end

    describe "with three arguments" do
      it "creates RGB from positional values" do
        color = build(218, 165, 32)
        expect(color.red.value).to(eq(218))
        expect(color.green.value).to(eq(165))
        expect(color.blue.value).to(eq(32))
      end
    end

    describe "with keyword arguments" do
      it "creates RGB from keyword arguments" do
        color = build(red: 218, green: 165, blue: 32)
        expect(color.red.value).to(eq(218))
        expect(color.green.value).to(eq(165))
        expect(color.blue.value).to(eq(32))
      end
    end

    describe "with invalid arguments" do
      it "raises error for invalid type" do
        expect { build([]) }.to(raise_error(ArgumentError, "Expected Integer or String, got Array"))
      end

      it "raises error for wrong number of arguments" do
        expect { build(1, 2) }.to(raise_error(ArgumentError, "Expected 1 or 3 arguments, got 2"))
      end
    end
  end

  describe "#pretty_print" do
    it "outputs standard Ruby format with colored swatch in class name" do
      rgb = new(red: 255, green: 0, blue: 0)
      io = StringIO.new
      PP.pp(rgb, io)

      output = io.string.chomp
      expect(output).to(include("\x1b["))
      expect(output).to(include("█"))
      expect(output).to(include("#<Unmagic::Color::RGB["))
      expect(output).to(include("@red=255"))
      expect(output).to(include("@green=0"))
      expect(output).to(include("@blue=0"))
    end
  end
end
