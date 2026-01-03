# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::RGB::Named) do
  describe ".parse" do
    it "parses a lowercase color name" do
      result = described_class.parse("goldenrod")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses an uppercase color name" do
      result = described_class.parse("GOLDENROD")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses a mixed case color name" do
      result = described_class.parse("GoldenRod")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses a color name with spaces" do
      result = described_class.parse("Golden Rod")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses basic named colors from X11 database" do
      expect(described_class.parse("red").to_hex).to(eq("#ff0000"))
      expect(described_class.parse("blue").to_hex).to(eq("#0000ff"))
      expect(described_class.parse("green").to_hex).to(eq("#00ff00")) # X11 value
    end

    it "raises ParseError for unknown color names" do
      expect do
        described_class.parse("notacolor")
      end.to(raise_error(Unmagic::Color::RGB::Named::ParseError, /Unknown color name in x11 database: "notacolor"/))
    end
  end

  describe ".valid?" do
    it "returns true for valid color names" do
      expect(described_class.valid?("goldenrod")).to(be(true))
      expect(described_class.valid?("red")).to(be(true))
      expect(described_class.valid?("blue")).to(be(true))
    end

    it "returns true for valid names with different casing" do
      expect(described_class.valid?("GOLDENROD")).to(be(true))
      expect(described_class.valid?("GoldenRod")).to(be(true))
    end

    it "returns true for valid names with spaces" do
      expect(described_class.valid?("Golden Rod")).to(be(true))
    end

    it "returns false for invalid color names" do
      expect(described_class.valid?("notacolor")).to(be(false))
      expect(described_class.valid?("invalid")).to(be(false))
    end
  end

  describe ".databases" do
    it "returns an array of database instances" do
      databases = described_class.databases
      expect(databases).to(be_an(Array))
      expect(databases.length).to(eq(2))
    end

    it "includes X11 database" do
      databases = described_class.databases
      expect(databases).to(include(Unmagic::Color::RGB::Named::X11))
    end

    it "includes CSS database" do
      databases = described_class.databases
      expect(databases).to(include(Unmagic::Color::RGB::Named::CSS))
    end

    it "allows accessing color names from databases" do
      x11 = described_class.databases.find { |db| db.name == "x11" }
      names = x11.all
      expect(names).to(include("goldenrod", "red", "blue", "green"))
    end
  end

  describe "database prefixes" do
    it "parses X11 colors by default" do
      color = described_class.parse("gray")
      expect(color.to_hex).to(eq("#bebebe"))
    end

    it "parses CSS colors with css: prefix" do
      color = described_class.parse("css:gray")
      expect(color.to_hex).to(eq("#808080"))
    end

    it "parses CSS colors with w3c: prefix" do
      color = described_class.parse("w3c:gray")
      expect(color.to_hex).to(eq("#808080"))
    end

    it "parses X11 colors with x11: prefix" do
      color = described_class.parse("x11:gray")
      expect(color.to_hex).to(eq("#bebebe"))
    end

    it "handles invalid prefix as color name" do
      expect do
        described_class.parse("invalid:unknowncolor")
      end.to(raise_error(Unmagic::Color::RGB::Named::ParseError, /Unknown color name in x11 database/))
    end

    it "handles whitespace in prefix" do
      color = described_class.parse("css: red")
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "validates colors with prefix" do
      expect(described_class.valid?("css:gray")).to(be(true))
      expect(described_class.valid?("x11:gray")).to(be(true))
      expect(described_class.valid?("css:notacolor")).to(be(false))
    end
  end

  describe "lazy loading" do
    it "loads X11 database when accessed" do
      described_class.parse("red")
      expect(Unmagic::Color::RGB::Named::X11.loaded?).to(be(true))
    end

    it "loads CSS database when accessed" do
      described_class.parse("css:red")
      expect(Unmagic::Color::RGB::Named::CSS.loaded?).to(be(true))
    end
  end

  describe "database differences" do
    it "returns different values for gray between databases" do
      x11_gray = described_class.parse("gray")
      css_gray = described_class.parse("css:gray")

      expect(x11_gray.to_hex).to(eq("#bebebe"))
      expect(css_gray.to_hex).to(eq("#808080"))
    end

    it "returns different values for green between databases" do
      x11_green = described_class.parse("green")
      css_green = described_class.parse("css:green")

      expect(x11_green.to_hex).to(eq("#00ff00"))
      expect(css_green.to_hex).to(eq("#008000"))
    end

    it "returns different values for maroon between databases" do
      x11_maroon = described_class.parse("maroon")
      css_maroon = described_class.parse("css:maroon")

      expect(x11_maroon.to_hex).to(eq("#b03060"))
      expect(css_maroon.to_hex).to(eq("#800000"))
    end

    it "returns different values for purple between databases" do
      x11_purple = described_class.parse("purple")
      css_purple = described_class.parse("css:purple")

      expect(x11_purple.to_hex).to(eq("#a020f0"))
      expect(css_purple.to_hex).to(eq("#800080"))
    end
  end

  describe "integration with Color.parse" do
    it "parses named colors through Color.parse" do
      color = Unmagic::Color.parse("goldenrod")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#daa520"))
    end

    it "parses named colors with bracket notation" do
      color = Unmagic::Color["red"]
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "handles case-insensitive parsing" do
      color = Unmagic::Color.parse("BLUE")
      expect(color.to_hex).to(eq("#0000ff"))
    end

    it "handles names with spaces" do
      color = Unmagic::Color.parse("dark golden rod")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#b8860b"))
    end

    it "still prioritizes hex over named colors" do
      # "abc" could be a name or a hex color, hex should win
      color = Unmagic::Color.parse("abc")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#aabbcc"))
    end

    it "parses CSS colors through Color.parse with prefix" do
      color = Unmagic::Color.parse("css:gray")
      expect(color).to(be_a(Unmagic::Color::RGB))
      expect(color.to_hex).to(eq("#808080"))
    end
  end
end
