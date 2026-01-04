# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::RGB::Named) do
  def parse(...)
    Unmagic::Color::RGB::Named.parse(...)
  end

  def valid?(...)
    Unmagic::Color::RGB::Named.valid?(...)
  end

  def find_by_name(...)
    Unmagic::Color::RGB::Named.find_by_name(...)
  end

  describe ".parse" do
    it "parses a lowercase color name" do
      result = parse("goldenrod")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses an uppercase color name" do
      result = parse("GOLDENROD")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses a mixed case color name" do
      result = parse("GoldenRod")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses a color name with spaces" do
      result = parse("Golden Rod")
      expect(result).to(be_a(Unmagic::Color::RGB))
      expect(result.to_hex).to(eq("#daa520"))
    end

    it "parses basic named colors from X11 database" do
      expect(parse("red").to_hex).to(eq("#ff0000"))
      expect(parse("blue").to_hex).to(eq("#0000ff"))
      expect(parse("green").to_hex).to(eq("#00ff00")) # X11 value
    end

    it "raises ParseError for unknown color names" do
      expect do
        parse("notacolor")
      end.to(raise_error(Unmagic::Color::RGB::Named::ParseError, /Unknown color name in x11 database: "notacolor"/))
    end
  end

  describe ".valid?" do
    it "returns true for valid color names" do
      expect(valid?("goldenrod")).to(be(true))
      expect(valid?("red")).to(be(true))
      expect(valid?("blue")).to(be(true))
    end

    it "returns true for valid names with different casing" do
      expect(valid?("GOLDENROD")).to(be(true))
      expect(valid?("GoldenRod")).to(be(true))
    end

    it "returns true for valid names with spaces" do
      expect(valid?("Golden Rod")).to(be(true))
    end

    it "returns false for invalid color names" do
      expect(valid?("notacolor")).to(be(false))
      expect(valid?("invalid")).to(be(false))
    end
  end

  describe ".databases" do
    it "returns an array of database instances" do
      databases = Unmagic::Color::RGB::Named.databases
      expect(databases).to(be_an(Array))
      expect(databases.length).to(eq(2))
    end

    it "includes X11 database" do
      databases = Unmagic::Color::RGB::Named.databases
      expect(databases).to(include(Unmagic::Color::RGB::Named::X11))
    end

    it "includes CSS database" do
      databases = Unmagic::Color::RGB::Named.databases
      expect(databases).to(include(Unmagic::Color::RGB::Named::CSS))
    end

    it "allows accessing color names from databases" do
      x11 = Unmagic::Color::RGB::Named.databases.find { |db| db.name == "x11" }
      names = x11.all
      expect(names).to(include("goldenrod", "red", "blue", "green"))
    end
  end

  describe "database prefixes" do
    it "parses X11 colors by default" do
      color = parse("gray")
      expect(color.to_hex).to(eq("#bebebe"))
    end

    it "parses CSS colors with css: prefix" do
      color = parse("css:gray")
      expect(color.to_hex).to(eq("#808080"))
    end

    it "parses CSS colors with w3c: prefix" do
      color = parse("w3c:gray")
      expect(color.to_hex).to(eq("#808080"))
    end

    it "parses X11 colors with x11: prefix" do
      color = parse("x11:gray")
      expect(color.to_hex).to(eq("#bebebe"))
    end

    it "handles invalid prefix as color name" do
      expect do
        parse("invalid:unknowncolor")
      end.to(raise_error(Unmagic::Color::RGB::Named::ParseError, /Unknown color name in x11 database/))
    end

    it "handles whitespace in prefix" do
      color = parse("css: red")
      expect(color.to_hex).to(eq("#ff0000"))
    end

    it "validates colors with prefix" do
      expect(valid?("css:gray")).to(be(true))
      expect(valid?("x11:gray")).to(be(true))
      expect(valid?("css:notacolor")).to(be(false))
    end
  end

  describe "lazy loading" do
    it "loads X11 database when accessed" do
      parse("red")
      expect(Unmagic::Color::RGB::Named::X11.loaded?).to(be(true))
    end

    it "loads CSS database when accessed" do
      parse("css:red")
      expect(Unmagic::Color::RGB::Named::CSS.loaded?).to(be(true))
    end
  end

  describe "database differences" do
    it "returns different values for gray between databases" do
      x11_gray = parse("gray")
      css_gray = parse("css:gray")

      expect(x11_gray.to_hex).to(eq("#bebebe"))
      expect(css_gray.to_hex).to(eq("#808080"))
    end

    it "returns different values for green between databases" do
      x11_green = parse("green")
      css_green = parse("css:green")

      expect(x11_green.to_hex).to(eq("#00ff00"))
      expect(css_green.to_hex).to(eq("#008000"))
    end

    it "returns different values for maroon between databases" do
      x11_maroon = parse("maroon")
      css_maroon = parse("css:maroon")

      expect(x11_maroon.to_hex).to(eq("#b03060"))
      expect(css_maroon.to_hex).to(eq("#800000"))
    end

    it "returns different values for purple between databases" do
      x11_purple = parse("purple")
      css_purple = parse("css:purple")

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
