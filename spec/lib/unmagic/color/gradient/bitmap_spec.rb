# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Gradient::Bitmap) do
  let(:red) { Unmagic::Color::RGB.parse("#FF0000") }
  let(:green) { Unmagic::Color::RGB.parse("#00FF00") }
  let(:blue) { Unmagic::Color::RGB.parse("#0000FF") }

  describe "#initialize" do
    it "accepts width, height, and pixels" do
      bitmap = described_class.new(width: 3, height: 1, pixels: [[red, green, blue]])
      expect(bitmap.width).to(eq(3))
      expect(bitmap.height).to(eq(1))
      expect(bitmap.pixels).to(eq([[red, green, blue]]))
    end
  end

  describe "#at" do
    it "returns pixel at coordinates" do
      bitmap = described_class.new(width: 3, height: 1, pixels: [[red, green, blue]])
      expect(bitmap.at(0, 0)).to(eq(red))
      expect(bitmap.at(1, 0)).to(eq(green))
      expect(bitmap.at(2, 0)).to(eq(blue))
    end

    it "defaults y to 0" do
      bitmap = described_class.new(width: 3, height: 1, pixels: [[red, green, blue]])
      expect(bitmap.at(0)).to(eq(red))
      expect(bitmap.at(1)).to(eq(green))
      expect(bitmap.at(2)).to(eq(blue))
    end

    it "works with multi-row bitmaps" do
      pixels = [
        [red, green, blue],
        [blue, red, green],
      ]
      bitmap = described_class.new(width: 3, height: 2, pixels: pixels)
      expect(bitmap.at(0, 0)).to(eq(red))
      expect(bitmap.at(1, 0)).to(eq(green))
      expect(bitmap.at(2, 0)).to(eq(blue))
      expect(bitmap.at(0, 1)).to(eq(blue))
      expect(bitmap.at(1, 1)).to(eq(red))
      expect(bitmap.at(2, 1)).to(eq(green))
    end
  end

  describe "#[]" do
    it "returns first pixel when called without arguments" do
      bitmap = described_class.new(width: 3, height: 1, pixels: [[red, green, blue]])
      expect(bitmap[]).to(eq(red))
    end

    it "delegates to #at when called with arguments" do
      bitmap = described_class.new(width: 3, height: 1, pixels: [[red, green, blue]])
      expect(bitmap[1, 0]).to(eq(green))
      expect(bitmap[2]).to(eq(blue))
    end
  end

  describe "#to_a" do
    it "returns flat array of all colors" do
      bitmap = described_class.new(width: 3, height: 1, pixels: [[red, green, blue]])
      expect(bitmap.to_a).to(eq([red, green, blue]))
    end

    it "flattens multi-row bitmaps left-to-right, top-to-bottom" do
      pixels = [
        [red, green],
        [blue, red],
      ]
      bitmap = described_class.new(width: 2, height: 2, pixels: pixels)
      expect(bitmap.to_a).to(eq([red, green, blue, red]))
    end
  end
end
