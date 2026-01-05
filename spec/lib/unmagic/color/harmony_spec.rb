# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Unmagic::Color::Harmony) do
  describe "#complementary" do
    it "returns a single color (not an array)" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.complementary
      expect(result).to(be_a(Unmagic::Color::RGB))
    end

    it "returns the complement with 180 degree hue shift" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.complementary
      expect(result.hue.value).to(eq(180))
    end

    it "wraps hue correctly" do
      color = Unmagic::Color::HSL.new(hue: 270, saturation: 100, lightness: 50)
      result = color.complementary
      expect(result.hue.value).to(eq(90)) # 270 + 180 = 450 % 360 = 90
    end

    it "preserves saturation and lightness" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 75, lightness: 40)
      result = color.complementary
      expect(result.saturation.value).to(eq(75))
      expect(result.lightness.value).to(eq(40))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 75, lightness: 40, alpha: 50)
      result = color.complementary
      expect(result.alpha.value).to(eq(50))
    end

    it "preserves color space for RGB input" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.complementary
      expect(result).to(be_a(Unmagic::Color::RGB))
    end

    it "preserves color space for HSL input" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.complementary
      expect(result).to(be_a(Unmagic::Color::HSL))
    end

    it "preserves color space for OKLCH input" do
      color = Unmagic::Color::OKLCH.new(lightness: 0.6, chroma: 0.15, hue: 30)
      result = color.complementary
      expect(result).to(be_a(Unmagic::Color::OKLCH))
    end
  end

  describe "#analogous" do
    it "returns an array of 2 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.analogous
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(2))
    end

    it "returns colors at -30 and +30 degrees by default" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 100, lightness: 50)
      result = color.analogous
      expect(result[0].hue.value).to(eq(30))  # 60 - 30
      expect(result[1].hue.value).to(eq(90))  # 60 + 30
    end

    it "accepts custom angle" do
      color = Unmagic::Color::HSL.new(hue: 60, saturation: 100, lightness: 50)
      result = color.analogous(angle: 15)
      expect(result[0].hue.value).to(eq(45))  # 60 - 15
      expect(result[1].hue.value).to(eq(75))  # 60 + 15
    end

    it "wraps hue correctly for negative angles" do
      color = Unmagic::Color::HSL.new(hue: 10, saturation: 100, lightness: 50)
      result = color.analogous
      expect(result[0].hue.value).to(eq(340)) # 10 - 30 = -20 -> 340
      expect(result[1].hue.value).to(eq(40))  # 10 + 30
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.analogous
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end
  end

  describe "#triadic" do
    it "returns an array of 2 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.triadic
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(2))
    end

    it "returns colors at +120 and +240 degrees" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.triadic
      expect(result[0].hue.value).to(eq(120))
      expect(result[1].hue.value).to(eq(240))
    end

    it "wraps hue correctly" do
      color = Unmagic::Color::HSL.new(hue: 200, saturation: 100, lightness: 50)
      result = color.triadic
      expect(result[0].hue.value).to(eq(320)) # 200 + 120
      expect(result[1].hue.value).to(eq(80))  # 200 + 240 = 440 % 360 = 80
    end

    it "preserves color space" do
      color = Unmagic::Color::OKLCH.new(lightness: 0.6, chroma: 0.15, hue: 0)
      result = color.triadic
      expect(result.all? { |c| c.is_a?(Unmagic::Color::OKLCH) }).to(be(true))
    end
  end

  describe "#split_complementary" do
    it "returns an array of 2 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.split_complementary
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(2))
    end

    it "returns colors at 150 and 210 degrees by default" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.split_complementary
      expect(result[0].hue.value).to(eq(150)) # 180 - 30
      expect(result[1].hue.value).to(eq(210)) # 180 + 30
    end

    it "accepts custom angle" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.split_complementary(angle: 45)
      expect(result[0].hue.value).to(eq(135)) # 180 - 45
      expect(result[1].hue.value).to(eq(225)) # 180 + 45
    end

    it "preserves color space" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.split_complementary
      expect(result.all? { |c| c.is_a?(Unmagic::Color::HSL) }).to(be(true))
    end
  end

  describe "#tetradic_square" do
    it "returns an array of 3 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.tetradic_square
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "returns colors at +90, +180, +270 degrees" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_square
      expect(result[0].hue.value).to(eq(90))
      expect(result[1].hue.value).to(eq(180))
      expect(result[2].hue.value).to(eq(270))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.tetradic_square
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end
  end

  describe "#tetradic_rectangle" do
    it "returns an array of 3 colors" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.tetradic_rectangle
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "returns colors at +60, +180, +240 degrees by default" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_rectangle
      expect(result[0].hue.value).to(eq(60))
      expect(result[1].hue.value).to(eq(180))
      expect(result[2].hue.value).to(eq(240))
    end

    it "accepts custom angle" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_rectangle(angle: 30)
      expect(result[0].hue.value).to(eq(30))
      expect(result[1].hue.value).to(eq(180))
      expect(result[2].hue.value).to(eq(210))
    end

    it "preserves color space" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tetradic_rectangle
      expect(result.all? { |c| c.is_a?(Unmagic::Color::HSL) }).to(be(true))
    end
  end

  describe "#monochromatic" do
    it "returns an array of colors" do
      color = Unmagic::Color.parse("#0000FF")
      result = color.monochromatic
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(5))
    end

    it "accepts custom step count" do
      color = Unmagic::Color.parse("#0000FF")
      result = color.monochromatic(steps: 3)
      expect(result.length).to(eq(3))
    end

    it "creates colors with varying lightness" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 100, lightness: 50)
      result = color.monochromatic(steps: 5)

      lightnesses = result.map { |c| c.lightness.value }
      # Should go from 15% to 85%
      expect(lightnesses.first).to(eq(15))
      expect(lightnesses.last).to(eq(85))
      # Should be sorted (ascending)
      expect(lightnesses).to(eq(lightnesses.sort))
    end

    it "preserves hue and saturation" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 80, lightness: 50)
      result = color.monochromatic(steps: 3)
      expect(result.all? { |c| c.hue.value == 240 }).to(be(true))
      expect(result.all? { |c| c.saturation.value == 80 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 100, lightness: 50, alpha: 75)
      result = color.monochromatic(steps: 3)
      expect(result.all? { |c| c.alpha.value == 75 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#0000FF")
      result = color.monochromatic
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#0000FF")
      expect { color.monochromatic(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end

  describe "#shades" do
    it "returns an array of darker colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.shades(steps: 3)
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "creates progressively darker colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 60)
      result = color.shades(steps: 3)
      lightnesses = result.map { |c| c.lightness.value }

      # All should be darker than original
      expect(lightnesses.all? { |l| l < 60 }).to(be(true))
      # Should be in descending order (getting darker)
      expect(lightnesses).to(eq(lightnesses.sort.reverse))
    end

    it "respects amount parameter" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 60)
      result_small = color.shades(steps: 3, amount: 0.3)
      result_large = color.shades(steps: 3, amount: 0.9)

      # Larger amount should produce darker shades
      expect(result_large.last.lightness.value).to(be < result_small.last.lightness.value)
    end

    it "preserves hue and saturation" do
      color = Unmagic::Color::HSL.new(hue: 120, saturation: 80, lightness: 50)
      result = color.shades(steps: 3)
      expect(result.all? { |c| c.hue.value == 120 }).to(be(true))
      expect(result.all? { |c| c.saturation.value == 80 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 120, saturation: 80, lightness: 50, alpha: 60)
      result = color.shades(steps: 3)
      expect(result.all? { |c| c.alpha.value == 60 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#FF0000")
      result = color.shades(steps: 3)
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end

    it "clamps lightness to 0" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 10)
      result = color.shades(steps: 5, amount: 1.0)
      expect(result.last.lightness.value).to(be >= 0)
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#FF0000")
      expect { color.shades(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end

  describe "#tints" do
    it "returns an array of lighter colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tints(steps: 3)
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "creates progressively lighter colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 40)
      result = color.tints(steps: 3)
      lightnesses = result.map { |c| c.lightness.value }

      # All should be lighter than original
      expect(lightnesses.all? { |l| l > 40 }).to(be(true))
      # Should be in ascending order (getting lighter)
      expect(lightnesses).to(eq(lightnesses.sort))
    end

    it "respects amount parameter" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 40)
      result_small = color.tints(steps: 3, amount: 0.3)
      result_large = color.tints(steps: 3, amount: 0.9)

      # Larger amount should produce lighter tints
      expect(result_large.last.lightness.value).to(be > result_small.last.lightness.value)
    end

    it "preserves hue and saturation" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 70, lightness: 50)
      result = color.tints(steps: 3)
      expect(result.all? { |c| c.hue.value == 240 }).to(be(true))
      expect(result.all? { |c| c.saturation.value == 70 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 240, saturation: 70, lightness: 50, alpha: 80)
      result = color.tints(steps: 3)
      expect(result.all? { |c| c.alpha.value == 80 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color::OKLCH.new(lightness: 0.5, chroma: 0.15, hue: 30)
      result = color.tints(steps: 3)
      expect(result.all? { |c| c.is_a?(Unmagic::Color::OKLCH) }).to(be(true))
    end

    it "clamps lightness to 100" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 90)
      result = color.tints(steps: 5, amount: 1.0)
      expect(result.last.lightness.value).to(be <= 100)
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#0000FF")
      expect { color.tints(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end

  describe "#tones" do
    it "returns an array of desaturated colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tones(steps: 3)
      expect(result).to(be_an(Array))
      expect(result.length).to(eq(3))
    end

    it "creates progressively less saturated colors" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result = color.tones(steps: 3)
      saturations = result.map { |c| c.saturation.value }

      # All should be less saturated than original
      expect(saturations.all? { |s| s < 100 }).to(be(true))
      # Should be in descending order (getting less saturated)
      expect(saturations).to(eq(saturations.sort.reverse))
    end

    it "respects amount parameter" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      result_small = color.tones(steps: 3, amount: 0.3)
      result_large = color.tones(steps: 3, amount: 0.9)

      # Larger amount should produce less saturated tones
      expect(result_large.last.saturation.value).to(be < result_small.last.saturation.value)
    end

    it "preserves hue and lightness" do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 80, lightness: 60)
      result = color.tones(steps: 3)
      expect(result.all? { |c| c.hue.value == 180 }).to(be(true))
      expect(result.all? { |c| c.lightness.value == 60 }).to(be(true))
    end

    it "preserves alpha" do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 80, lightness: 60, alpha: 90)
      result = color.tones(steps: 3)
      expect(result.all? { |c| c.alpha.value == 90 }).to(be(true))
    end

    it "preserves color space" do
      color = Unmagic::Color.parse("#00FF00")
      result = color.tones(steps: 3)
      expect(result.all? { |c| c.is_a?(Unmagic::Color::RGB) }).to(be(true))
    end

    it "clamps saturation to 0" do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 20, lightness: 50)
      result = color.tones(steps: 5, amount: 1.0)
      expect(result.last.saturation.value).to(be >= 0)
    end

    it "raises error for invalid steps" do
      color = Unmagic::Color.parse("#00FF00")
      expect { color.tones(steps: 0) }.to(raise_error(ArgumentError, "steps must be at least 1"))
    end
  end

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
