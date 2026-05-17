# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#scale" do
    let(:base) { Unmagic::Color::OKLCH.new(lightness: 0.62, chroma: 0.21, hue: 260) }

    it "returns the requested number of OKLCH colors" do
      result = base.scale(steps: 7)
      expect(result.length).to(eq(7))
      expect(result).to(all(be_a(Unmagic::Color::OKLCH)))
    end

    it "defaults to an 11-step scale" do
      expect(base.scale.length).to(eq(11))
    end

    it "orders colors from lightest to darkest" do
      lightnesses = base.scale(steps: 9).map(&:lightness)
      expect(lightnesses).to(eq(lightnesses.sort.reverse))
    end

    it "works from any color space, converting through OKLCH" do
      expect(Unmagic::Color.parse("#3366cc").scale(steps: 5)).to(all(be_a(Unmagic::Color::OKLCH)))
      expect(Unmagic::Color::HSL.new(hue: 200, saturation: 70, lightness: 50).scale(steps: 5).length).to(eq(5))
    end

    it "raises when steps is less than 2" do
      expect { base.scale(steps: 1) }.to(raise_error(ArgumentError, /at least 2/))
    end

    describe "anchor" do
      it "places the base color exactly at the anchored index" do
        anchored = base.scale(steps: 11, anchor: 5, gamut: :none)[5]
        expect(anchored.lightness).to(be_within(1e-6).of(0.62))
        expect(anchored.chroma.value).to(be_within(1e-6).of(0.21))
        expect(anchored.hue.value).to(be_within(1e-6).of(260))
      end

      it "keeps the scale monotonic around the anchor" do
        lightnesses = base.scale(steps: 11, anchor: 3, gamut: :none).map(&:lightness)
        expect(lightnesses).to(eq(lightnesses.sort.reverse))
      end

      it "raises when the anchor is out of range" do
        expect { base.scale(steps: 11, anchor: 11) }.to(raise_error(ArgumentError, /anchor/))
      end
    end

    describe "chroma" do
      it ":flat holds chroma constant at the base chroma" do
        chromas = base.scale(steps: 7, chroma: :flat, gamut: :none).map { |c| c.chroma.value }
        expect(chromas).to(all(be_within(1e-6).of(0.21)))
      end

      it ":peak peaks in the mid-tones and tapers toward both ends" do
        chromas = base.scale(steps: 11, chroma: :peak, gamut: :none).map { |c| c.chroma.value }
        peak = chromas.index(chromas.max)
        expect(peak).to(be_between(3, 7))
        expect(chromas.first).to(be < chromas[peak])
        expect(chromas.last).to(be < chromas[peak])
      end

      it "accepts an explicit array of chroma values" do
        chromas = base.scale(steps: 4, chroma: [0.05, 0.1, 0.15, 0.2], gamut: :none).map { |c| c.chroma.value }
        expect(chromas).to(eq([0.05, 0.1, 0.15, 0.2]))
      end

      it "accepts a proc called with position and index" do
        chromas = base.scale(steps: 5, chroma: ->(t, _i) { t * 0.2 }, gamut: :none).map { |c| c.chroma.value }
        expect(chromas.first).to(be_within(1e-6).of(0.0))
        expect(chromas.last).to(be_within(1e-6).of(0.2))
      end
    end

    describe "hue_shift" do
      it "keeps hue constant by default" do
        hues = base.scale(steps: 7, gamut: :none).map { |c| c.hue.value }
        expect(hues).to(all(be_within(1e-6).of(260)))
      end

      it "drifts hue linearly across a range" do
        hues = base.scale(steps: 3, hue_shift: -10..10, gamut: :none).map { |c| c.hue.value }
        expect(hues[0]).to(be_within(1e-6).of(250))
        expect(hues[1]).to(be_within(1e-6).of(260))
        expect(hues[2]).to(be_within(1e-6).of(270))
      end
    end

    describe "lightness" do
      it "accepts a range of light and dark endpoints" do
        scale = base.scale(steps: 5, lightness: 0.95..0.2, gamut: :none)
        expect(scale.first.lightness).to(be_within(1e-6).of(0.95))
        expect(scale.last.lightness).to(be_within(1e-6).of(0.2))
      end

      it "accepts an explicit array of lightness values" do
        scale = base.scale(steps: 4, lightness: [0.9, 0.7, 0.5, 0.3], gamut: :none)
        expect(scale.map(&:lightness)).to(eq([0.9, 0.7, 0.5, 0.3]))
      end
    end

    describe "gamut" do
      it ":srgb (the default) keeps every color displayable" do
        expect(base.scale(steps: 11).map(&:in_gamut?)).to(all(be(true)))
      end

      it ":none leaves colors unclamped, even outside sRGB" do
        vivid = Unmagic::Color::OKLCH.new(lightness: 0.62, chroma: 0.21, hue: 260)
        expect(vivid.scale(steps: 11, anchor: 5, gamut: :none).map(&:in_gamut?)).to(include(false))
      end

      it "rejects an unknown gamut" do
        expect { base.scale(gamut: :p3) }.to(raise_error(ArgumentError, /gamut/))
      end
    end
  end
end
