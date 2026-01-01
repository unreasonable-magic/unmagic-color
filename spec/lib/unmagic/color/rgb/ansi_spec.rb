# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::RGB::ANSI) do
  describe ".parse" do
    context "with standard 3/4-bit colors" do
      it "parses foreground colors (30-37)" do
        expect(described_class.parse("30").to_hex).to(eq("#000000")) # black
        expect(described_class.parse("31").to_hex).to(eq("#ff0000")) # red
        expect(described_class.parse("32").to_hex).to(eq("#00ff00")) # green
        expect(described_class.parse("33").to_hex).to(eq("#ffff00")) # yellow
        expect(described_class.parse("34").to_hex).to(eq("#0000ff")) # blue
        expect(described_class.parse("35").to_hex).to(eq("#ff00ff")) # magenta
        expect(described_class.parse("36").to_hex).to(eq("#00ffff")) # cyan
        expect(described_class.parse("37").to_hex).to(eq("#ffffff")) # white
      end

      it "parses background colors (40-47)" do
        expect(described_class.parse("40").to_hex).to(eq("#000000")) # black
        expect(described_class.parse("41").to_hex).to(eq("#ff0000")) # red
        expect(described_class.parse("42").to_hex).to(eq("#00ff00")) # green
        expect(described_class.parse("43").to_hex).to(eq("#ffff00")) # yellow
        expect(described_class.parse("44").to_hex).to(eq("#0000ff")) # blue
        expect(described_class.parse("45").to_hex).to(eq("#ff00ff")) # magenta
        expect(described_class.parse("46").to_hex).to(eq("#00ffff")) # cyan
        expect(described_class.parse("47").to_hex).to(eq("#ffffff")) # white
      end

      it "parses bright foreground colors (90-97)" do
        expect(described_class.parse("90").to_hex).to(eq("#000000")) # bright black
        expect(described_class.parse("91").to_hex).to(eq("#ff0000")) # bright red
        expect(described_class.parse("92").to_hex).to(eq("#00ff00")) # bright green
        expect(described_class.parse("93").to_hex).to(eq("#ffff00")) # bright yellow
        expect(described_class.parse("94").to_hex).to(eq("#0000ff")) # bright blue
        expect(described_class.parse("95").to_hex).to(eq("#ff00ff")) # bright magenta
        expect(described_class.parse("96").to_hex).to(eq("#00ffff")) # bright cyan
        expect(described_class.parse("97").to_hex).to(eq("#ffffff")) # bright white
      end

      it "parses bright background colors (100-107)" do
        expect(described_class.parse("100").to_hex).to(eq("#000000")) # bright black
        expect(described_class.parse("101").to_hex).to(eq("#ff0000")) # bright red
        expect(described_class.parse("102").to_hex).to(eq("#00ff00")) # bright green
        expect(described_class.parse("103").to_hex).to(eq("#ffff00")) # bright yellow
        expect(described_class.parse("104").to_hex).to(eq("#0000ff")) # bright blue
        expect(described_class.parse("105").to_hex).to(eq("#ff00ff")) # bright magenta
        expect(described_class.parse("106").to_hex).to(eq("#00ffff")) # bright cyan
        expect(described_class.parse("107").to_hex).to(eq("#ffffff")) # bright white
      end
    end

    context "with 256-color palette" do
      it "parses foreground 256-color codes" do
        result = described_class.parse("38;5;196")
        expect(result).to(be_a(Unmagic::Color::RGB))
        expect(result.to_hex).to(eq("#ff0000"))
      end

      it "parses background 256-color codes" do
        result = described_class.parse("48;5;196")
        expect(result).to(be_a(Unmagic::Color::RGB))
        expect(result.to_hex).to(eq("#ff0000"))
      end

      it "parses standard colors (0-15)" do
        expect(described_class.parse("38;5;0").to_hex).to(eq("#000000"))
        expect(described_class.parse("38;5;1").to_hex).to(eq("#ff0000"))
        expect(described_class.parse("38;5;7").to_hex).to(eq("#ffffff"))
      end

      it "parses RGB cube colors (16-231)" do
        # Color 16 = RGB(0, 0, 0)
        expect(described_class.parse("38;5;16").to_hex).to(eq("#000000"))
        # Color 231 = RGB(255, 255, 255)
        expect(described_class.parse("38;5;231").to_hex).to(eq("#ffffff"))
        # Color 46 = RGB(0, 255, 0)
        expect(described_class.parse("38;5;46").to_hex).to(eq("#00ff00"))
      end

      it "parses grayscale colors (232-255)" do
        # Color 232 = RGB(8, 8, 8)
        expect(described_class.parse("38;5;232").to_hex).to(eq("#080808"))
        # Color 255 = RGB(238, 238, 238)
        expect(described_class.parse("38;5;255").to_hex).to(eq("#eeeeee"))
      end
    end

    context "with 24-bit true color" do
      it "parses foreground true color" do
        result = described_class.parse("38;2;100;150;200")
        expect(result).to(be_a(Unmagic::Color::RGB))
        expect(result.red.value).to(eq(100))
        expect(result.green.value).to(eq(150))
        expect(result.blue.value).to(eq(200))
      end

      it "parses background true color" do
        result = described_class.parse("48;2;255;128;64")
        expect(result).to(be_a(Unmagic::Color::RGB))
        expect(result.red.value).to(eq(255))
        expect(result.green.value).to(eq(128))
        expect(result.blue.value).to(eq(64))
      end

      it "parses black true color" do
        result = described_class.parse("38;2;0;0;0")
        expect(result.to_hex).to(eq("#000000"))
      end

      it "parses white true color" do
        result = described_class.parse("38;2;255;255;255")
        expect(result.to_hex).to(eq("#ffffff"))
      end
    end

    context "with error cases" do
      it "raises ParseError for empty string" do
        expect do
          described_class.parse("")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Can't parse empty string/))
      end

      it "raises ParseError for invalid input type" do
        expect do
          described_class.parse(nil)
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Input must be a string or integer/))
      end

      it "raises ParseError for invalid format" do
        expect do
          described_class.parse("abc")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Invalid ANSI format/))
      end

      it "raises ParseError for unknown color code" do
        expect do
          described_class.parse("99")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Unknown ANSI color code/))
      end

      it "raises ParseError for invalid 256-color index" do
        expect do
          described_class.parse("38;5;256")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /256-color index must be 0-255/))
      end

      it "raises ParseError for invalid true color RGB values" do
        expect do
          described_class.parse("38;2;300;0;0")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Red must be 0-255/))

        expect do
          described_class.parse("38;2;0;256;0")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Green must be 0-255/))
      end

      it "raises ParseError for incomplete 256-color format" do
        expect do
          described_class.parse("38;5")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Extended color format requires at least 3 parameters|256-color format requires 3 parameters/))
      end

      it "raises ParseError for incomplete true color format" do
        expect do
          described_class.parse("38;2;255;0")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /True color format requires 5 parameters/))
      end

      it "raises ParseError for unknown extended color type" do
        expect do
          described_class.parse("38;9;100")
        end.to(raise_error(Unmagic::Color::RGB::ANSI::ParseError, /Unknown extended color type: 9/))
      end
    end

    context "with edge cases" do
      it "handles leading zeros" do
        result = described_class.parse("031")
        expect(result.to_hex).to(eq("#ff0000"))
      end

      it "strips whitespace" do
        result = described_class.parse("  31  ")
        expect(result.to_hex).to(eq("#ff0000"))
      end
    end

    context "with integer input" do
      it "parses integer ANSI codes" do
        result = described_class.parse(31)
        expect(result.to_hex).to(eq("#ff0000"))
      end

      it "parses background color integers" do
        result = described_class.parse(41)
        expect(result.to_hex).to(eq("#ff0000"))
      end

      it "parses bright color integers" do
        result = described_class.parse(91)
        expect(result.to_hex).to(eq("#ff0000"))
      end

      it "parses bright background color integers" do
        result = described_class.parse(101)
        expect(result.to_hex).to(eq("#ff0000"))
      end
    end
  end

  describe ".valid?" do
    it "returns true for valid ANSI codes" do
      expect(described_class.valid?("31")).to(be(true))
      expect(described_class.valid?("38;5;196")).to(be(true))
      expect(described_class.valid?("38;2;255;0;0")).to(be(true))
    end

    it "returns false for invalid codes" do
      expect(described_class.valid?("abc")).to(be(false))
      expect(described_class.valid?("99")).to(be(false))
      expect(described_class.valid?("")).to(be(false))
    end
  end

  describe "integration with RGB.parse" do
    it "parses ANSI codes through RGB.parse" do
      color = Unmagic::Color::RGB.parse("31")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses 256-color codes through RGB.parse" do
      color = Unmagic::Color::RGB.parse("38;5;196")
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses true color codes through RGB.parse" do
      color = Unmagic::Color::RGB.parse("38;2;100;150;200")
      expect(color.red.value).to(eq(100))
    end
  end

  describe "integration with Color.parse" do
    it "parses ANSI codes through Color.parse" do
      color = Unmagic::Color.parse("31")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "parses with bracket notation" do
      color = Unmagic::Color["38;2;255;0;0"]
      expect(color.to_hex).to(eq("#ff0000"))
    end
  end
end
