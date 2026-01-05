# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "edge cases" do
    describe "grayscale colors" do
      it "handles grayscale for harmony methods" do
        gray = Unmagic::Color::HSL.new(hue: 0, saturation: 0, lightness: 50)

        # Grayscale has no meaningful hue, but methods should still work
        expect { gray.complementary }.not_to(raise_error)
        expect { gray.triadic }.not_to(raise_error)
        expect { gray.analogous }.not_to(raise_error)
      end

      it "handles grayscale for variation methods" do
        gray = Unmagic::Color::HSL.new(hue: 0, saturation: 0, lightness: 50)

        shades = gray.shades(steps: 3)
        tints = gray.tints(steps: 3)
        tones = gray.tones(steps: 3)

        expect(shades.length).to(eq(3))
        expect(tints.length).to(eq(3))
        expect(tones.length).to(eq(3))
      end
    end

    describe "extreme values" do
      it "handles pure white" do
        white = Unmagic::Color::HSL.new(hue: 0, saturation: 0, lightness: 100)

        # Tints from white are still white (can't get lighter)
        tints = white.tints(steps: 3)
        expect(tints.all? { |c| c.lightness.value == 100 }).to(be(true))

        # Shades from white work normally
        shades = white.shades(steps: 3)
        expect(shades.all? { |c| c.lightness.value < 100 }).to(be(true))
      end

      it "handles pure black" do
        black = Unmagic::Color::HSL.new(hue: 0, saturation: 0, lightness: 0)

        # Shades from black stay black (can't get darker)
        shades = black.shades(steps: 3)
        expect(shades.all? { |c| c.lightness.value == 0 }).to(be(true))

        # Tints from black work normally
        tints = black.tints(steps: 3)
        expect(tints.all? { |c| c.lightness.value > 0 }).to(be(true))
      end
    end
  end
end
