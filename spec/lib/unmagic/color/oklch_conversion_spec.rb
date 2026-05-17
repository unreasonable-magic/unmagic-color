# frozen_string_literal: true

require "spec_helper"

# Exercises the OKLab color-science pipeline that backs OKLCH <-> sRGB
# conversion and sRGB gamut handling.
RSpec.describe(Unmagic::Color::OKLCH) do
  def rgb(hex) = Unmagic::Color::RGB.parse(hex)
  def oklch(l, c, h) = Unmagic::Color::OKLCH.new(lightness: l, chroma: c, hue: h)

  describe "RGB -> OKLCH -> RGB round trip" do
    it "is exact for the sRGB primaries, secondaries, black and white" do
      ["#000000", "#ffffff", "#ff0000", "#00ff00", "#0000ff", "#ffff00", "#00ffff", "#ff00ff"].each do |hex|
        expect(rgb(hex).to_oklch.to_rgb.to_hex).to(eq(hex))
      end
    end

    it "round trips arbitrary colors within one unit per channel" do
      [[51, 102, 153], [218, 165, 32], [123, 45, 200], [9, 240, 17]].each do |r, g, b|
        source = Unmagic::Color::RGB.new(red: r, green: g, blue: b)
        result = source.to_oklch.to_rgb
        expect(result.red.value).to(be_within(1).of(r))
        expect(result.green.value).to(be_within(1).of(g))
        expect(result.blue.value).to(be_within(1).of(b))
      end
    end
  end

  describe "known OKLab landmarks" do
    it "places white at lightness 1.0 with no chroma" do
      white = rgb("#ffffff").to_oklch
      expect(white.lightness).to(be_within(0.001).of(1.0))
      expect(white.chroma.value).to(be_within(0.001).of(0.0))
    end

    it "places black at lightness 0.0" do
      expect(rgb("#000000").to_oklch.lightness).to(be_within(0.001).of(0.0))
    end

    it "leaves a neutral gray with effectively zero chroma" do
      expect(rgb("#808080").to_oklch.chroma.value).to(be_within(0.001).of(0.0))
    end

    it "matches the published OKLCH for Tailwind v4 red-500 (#fb2c36)" do
      red = rgb("#fb2c36").to_oklch
      expect(red.lightness).to(be_within(0.005).of(0.637))
      expect(red.chroma.value).to(be_within(0.005).of(0.237))
      expect(red.hue.value).to(be_within(0.5).of(25.331))
    end
  end

  describe "#to_oklab" do
    it "returns the cartesian [L, a, b] form of the OKLCH color" do
      l, a, b = oklch(0.65, 0.15, 0).to_oklab
      expect(l).to(be_within(0.001).of(0.65))
      expect(a).to(be_within(0.001).of(0.15)) # hue 0 -> all chroma on +a
      expect(b).to(be_within(0.001).of(0.0))
    end
  end

  describe "#in_gamut?" do
    it "is true for a moderate color well inside sRGB" do
      expect(oklch(0.6, 0.1, 240).in_gamut?).to(be(true))
    end

    it "is false for a chroma no sRGB display can show" do
      expect(oklch(0.95, 0.3, 140).in_gamut?).to(be(false))
    end
  end

  describe "#clamp_to_gamut" do
    it "returns an in-gamut color" do
      expect(oklch(0.95, 0.3, 140).clamp_to_gamut.in_gamut?).to(be(true))
    end

    it "reduces chroma while preserving lightness and hue" do
      original = oklch(0.95, 0.3, 140)
      clamped = original.clamp_to_gamut
      expect(clamped.chroma.value).to(be < original.chroma.value)
      expect(clamped.lightness).to(be_within(0.001).of(original.lightness))
      expect(clamped.hue.value).to(be_within(0.001).of(original.hue.value))
    end

    it "leaves an already displayable color unchanged" do
      displayable = oklch(0.6, 0.1, 240)
      expect(displayable.clamp_to_gamut.chroma.value).to(eq(displayable.chroma.value))
    end
  end
end
