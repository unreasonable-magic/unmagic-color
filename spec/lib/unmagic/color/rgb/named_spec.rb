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

    it "parses basic named colors" do
      expect(described_class.parse("red").to_hex).to(eq("#ff0000"))
      expect(described_class.parse("blue").to_hex).to(eq("#0000ff"))
      expect(described_class.parse("green").to_hex).to(eq("#008000"))
    end

    it "raises ParseError for unknown color names" do
      expect do
        described_class.parse("notacolor")
      end.to(raise_error(Unmagic::Color::RGB::Named::ParseError, /Unknown color name: "notacolor"/))
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

  describe ".all" do
    it "returns an array of color names" do
      names = described_class.all
      expect(names).to(be_an(Array))
      expect(names).to(include("goldenrod", "red", "blue", "green"))
    end

    it "returns all 164 colors from rgb.txt" do
      names = described_class.all
      expect(names.length).to(be >= 140)
    end
  end

  describe "memoization" do
    it "loads data only once" do
      # First call
      data1 = described_class.send(:data)

      # Second call should return the same object
      data2 = described_class.send(:data)

      expect(data1.object_id).to(eq(data2.object_id))
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
  end
end
