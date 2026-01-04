# frozen_string_literal: true

require "spec_helper"
require "pp"
require "stringio"

RSpec.describe(Unmagic::Color::HSL) do
  def parse(...)
    Unmagic::Color::HSL.parse(...)
  end

  def new(...)
    Unmagic::Color::HSL.new(...)
  end

  def derive(...)
    Unmagic::Color::HSL.derive(...)
  end

  describe ".parse" do
    it "parses HSL with parentheses and percents" do
      color = parse("hsl(180, 50%, 50%)")
      expect(color).to(be_a(Unmagic::Color::HSL))
      expect(color.hue).to(eq(180))
      expect(color.saturation).to(eq(50))
      expect(color.lightness).to(eq(50))
    end

    it "parses HSL without parentheses" do
      color = parse("180, 50%, 50%")
      expect(color).to(be_a(Unmagic::Color::HSL))
      expect(color.hue).to(eq(180))
      expect(color.saturation).to(eq(50))
      expect(color.lightness).to(eq(50))
    end

    it "parses HSL without percent signs" do
      color = parse("hsl(180, 50, 50)")
      expect(color.hue).to(eq(180))
      expect(color.saturation).to(eq(50))
      expect(color.lightness).to(eq(50))
    end

    it "parses HSL with extra spaces" do
      color = parse("hsl(  180  ,  50%  ,  50%  )")
      expect(color.hue).to(eq(180))
      expect(color.saturation).to(eq(50))
      expect(color.lightness).to(eq(50))
    end

    it "converts to RGB correctly" do
      # Red
      red = parse("hsl(0, 100%, 50%)")
      red_rgb = red.to_rgb
      expect(red_rgb.red).to(eq(255))
      expect(red_rgb.green).to(eq(0))
      expect(red_rgb.blue).to(eq(0))

      # Green
      green = parse("hsl(120, 100%, 50%)")
      green_rgb = green.to_rgb
      expect(green_rgb.red).to(eq(0))
      expect(green_rgb.green).to(eq(255))
      expect(green_rgb.blue).to(eq(0))

      # Blue
      blue = parse("hsl(240, 100%, 50%)")
      blue_rgb = blue.to_rgb
      expect(blue_rgb.red).to(eq(0))
      expect(blue_rgb.green).to(eq(0))
      expect(blue_rgb.blue).to(eq(255))

      # Gray
      gray = parse("hsl(0, 0%, 50%)")
      gray_rgb = gray.to_rgb
      expect(gray_rgb.red).to(eq(128))
      expect(gray_rgb.green).to(eq(128))
      expect(gray_rgb.blue).to(eq(128))

      # White
      white = parse("hsl(0, 0%, 100%)")
      white_rgb = white.to_rgb
      expect(white_rgb.red).to(eq(255))
      expect(white_rgb.green).to(eq(255))
      expect(white_rgb.blue).to(eq(255))

      # Black
      black = parse("hsl(0, 0%, 0%)")
      black_rgb = black.to_rgb
      expect(black_rgb.red).to(eq(0))
      expect(black_rgb.green).to(eq(0))
      expect(black_rgb.blue).to(eq(0))
    end

    it "handles hue wrapping" do
      color1 = parse("hsl(0, 100%, 50%)")
      color2 = parse("hsl(360, 100%, 50%)")
      expect(color1.to_rgb.to_hex).to(eq(color2.to_rgb.to_hex))
    end

    it "raises ParseError for invalid input" do
      expect { parse("hsl(180, 50%)") }.to(raise_error(Unmagic::Color::HSL::ParseError))
      expect { parse("hsl(red, green, blue)") }.to(raise_error(Unmagic::Color::HSL::ParseError))
      expect { parse("180 50 50") }.to(raise_error(Unmagic::Color::HSL::ParseError))
      expect { parse("") }.to(raise_error(Unmagic::Color::HSL::ParseError))
      expect { parse(nil) }.to(raise_error(Unmagic::Color::HSL::ParseError))
      expect { parse(123) }.to(raise_error(Unmagic::Color::HSL::ParseError))
    end
  end

  describe ".derive" do
    it "generates consistent colors from integer seeds" do
      color1 = derive(12345)
      color2 = derive(12345)
      expect(color1.hue).to(eq(color2.hue))
      expect(color1.saturation).to(eq(color2.saturation))
      expect(color1.lightness).to(eq(color2.lightness))
    end

    it "generates different colors for different seeds" do
      color1 = derive(12345)
      color2 = derive(54321)
      expect(color1).not_to(eq(color2))
    end

    it "respects custom parameters" do
      color = derive(12345, lightness: 70, saturation_range: (20..40))
      expect(color.lightness).to(eq(70))
      expect(color.saturation).to(be_between(20, 40))
    end

    it "raises error for non-integer seeds" do
      expect { derive("not_integer") }.to(raise_error(ArgumentError, "Seed must be an integer"))
      expect { derive(3.14) }.to(raise_error(ArgumentError, "Seed must be an integer"))
    end
  end

  describe "#new" do
    it "creates HSL color with keyword arguments" do
      color = new(hue: 180, saturation: 50, lightness: 50)
      expect(color.hue).to(eq(180))
      expect(color.saturation).to(eq(50))
      expect(color.lightness).to(eq(50))
    end

    it "wraps hue values" do
      color = new(hue: 720, saturation: 50, lightness: 50)
      expect(color.hue).to(eq(0)) # 720 % 360 = 0
    end

    it "clamps saturation to 0-100" do
      color = new(hue: 180, saturation: 150, lightness: 50)
      expect(color.saturation).to(eq(100))
    end

    it "clamps lightness to 0-100" do
      color = new(hue: 180, saturation: 50, lightness: -50)
      expect(color.lightness).to(eq(0))
    end
  end

  describe "#to_hsl" do
    it "returns itself" do
      color = new(hue: 180, saturation: 50, lightness: 50)
      expect(color.to_hsl).to(eq(color))
    end
  end

  describe "methods" do
    it "has expected methods" do
      color = new(hue: 180, saturation: 50, lightness: 50)
      expect(color).to(be_a(Unmagic::Color::HSL))
      expect(color).to(respond_to(:luminance))
      expect(color).to(respond_to(:blend))
    end

    it "can convert to RGB after initialization" do
      color = new(hue: 0, saturation: 100, lightness: 50)
      rgb = color.to_rgb
      expect(rgb.red).to(eq(255))
      expect(rgb.green).to(eq(0))
      expect(rgb.blue).to(eq(0))
    end
  end

  describe "#progression" do
    let(:base_hsl) { new(hue: 180, saturation: 50, lightness: 50) }

    it "creates the specified number of color steps" do
      progression = base_hsl.progression(steps: 5, lightness: ->(_hsl, _i) { 80 })
      expect(progression.length).to(eq(5))
      expect(progression.all? { |color| color.is_a?(Unmagic::Color::HSL) }).to(be(true))
    end

    it "applies lightness transformation using provided proc" do
      # Simple hardcoded lightness
      progression = base_hsl.progression(steps: 3, lightness: ->(_hsl, _i) { 80 })
      expect(progression.all? { |color| color.lightness == 80 }).to(be(true))
      expect(progression.all? { |color| color.hue == 180 }).to(be(true))
      expect(progression.all? { |color| color.saturation == 50 }).to(be(true))
    end

    it "provides step index to lightness proc" do
      # Lightness increases by step index * 10
      progression = base_hsl.progression(steps: 4, lightness: ->(_hsl, i) { 10 + (i * 20) })
      expect(progression[0].lightness).to(eq(10))  # step 0: 10 + (0 * 20)
      expect(progression[1].lightness).to(eq(30))  # step 1: 10 + (1 * 20)
      expect(progression[2].lightness).to(eq(50))  # step 2: 10 + (2 * 20)
      expect(progression[3].lightness).to(eq(70))  # step 3: 10 + (3 * 20)
    end

    it "provides HSL instance to lightness proc" do
      # Lightness based on current HSL values
      progression = base_hsl.progression(
        steps: 3,
        lightness: ->(hsl, _i) { hsl.lightness < 50 ? 20 : 80 },
      )
      expect(progression.all? { |color| color.lightness == 80 }).to(be(true))
    end

    it "applies saturation transformation when provided" do
      progression = base_hsl.progression(
        steps: 3,
        lightness: ->(_hsl, _i) { 50 },
        saturation: ->(_hsl, i) { 20 + (i * 15) },
      )
      expect(progression[0].saturation).to(eq(20))  # step 0: 20 + (0 * 15)
      expect(progression[1].saturation).to(eq(35))  # step 1: 20 + (1 * 15)
      expect(progression[2].saturation).to(eq(50))  # step 2: 20 + (2 * 15)
    end

    it "keeps original saturation when saturation proc not provided" do
      progression = base_hsl.progression(steps: 3, lightness: ->(_hsl, _i) { 80 })
      expect(progression.all? { |color| color.saturation == 50 }).to(be(true))
    end

    it "clamps lightness values to 0-100" do
      progression = base_hsl.progression(
        steps: 3,
        lightness: ->(_hsl, i) {
          if i == 0
            -10
          else
            (i == 1 ? 50 : 110)
          end
        },
      )
      expect(progression[0].lightness).to(eq(0))    # -10 clamped to 0
      expect(progression[1].lightness).to(eq(50))   # 50 unchanged
      expect(progression[2].lightness).to(eq(100))  # 110 clamped to 100
    end

    it "clamps saturation values to 0-100" do
      progression = base_hsl.progression(
        steps: 3,
        lightness: ->(_hsl, _i) { 50 },
        saturation: ->(_hsl, i) {
          if i == 0
            -5
          else
            (i == 1 ? 50 : 150)
          end
        },
      )
      expect(progression[0].saturation).to(eq(0))    # -5 clamped to 0
      expect(progression[1].saturation).to(eq(50))   # 50 unchanged
      expect(progression[2].saturation).to(eq(100))  # 150 clamped to 100
    end

    it "preserves hue across all steps" do
      progression = base_hsl.progression(steps: 5, lightness: ->(_hsl, i) { i * 20 })
      expect(progression.all? { |color| color.hue == 180 }).to(be(true))
    end

    it "works with complex progression logic" do
      # Theme-like progression: lighter in middle, darker at ends
      progression = base_hsl.progression(
        steps: 5,
        lightness: ->(_hsl, i) do
          case i
          when 0, 4 then 20  # dark at ends
          when 1, 3 then 40  # medium
          when 2 then 80     # light in middle
          end
        end,
        saturation: ->(hsl, i) { i < 3 ? hsl.saturation : hsl.saturation - 10 },
      )

      expect(progression[0].lightness).to(eq(20))
      expect(progression[1].lightness).to(eq(40))
      expect(progression[2].lightness).to(eq(80))
      expect(progression[3].lightness).to(eq(40))
      expect(progression[4].lightness).to(eq(20))

      expect(progression[0].saturation).to(eq(50))  # < 3, unchanged
      expect(progression[1].saturation).to(eq(50))  # < 3, unchanged
      expect(progression[2].saturation).to(eq(50))  # < 3, unchanged
      expect(progression[3].saturation).to(eq(40))  # >= 3, reduced by 10
      expect(progression[4].saturation).to(eq(40))  # >= 3, reduced by 10
    end

    describe "array support" do
      it "accepts arrays for lightness values" do
        progression = base_hsl.progression(steps: 3, lightness: [20, 40, 60])
        expect(progression[0].lightness).to(eq(20))
        expect(progression[1].lightness).to(eq(40))
        expect(progression[2].lightness).to(eq(60))
        expect(progression.all? { |color| color.hue == 180 }).to(be(true))
        expect(progression.all? { |color| color.saturation == 50 }).to(be(true))
      end

      it "uses last array value when steps exceed array length" do
        progression = base_hsl.progression(steps: 5, lightness: [20, 40, 60])
        expect(progression[0].lightness).to(eq(20))
        expect(progression[1].lightness).to(eq(40))
        expect(progression[2].lightness).to(eq(60))
        expect(progression[3].lightness).to(eq(60))  # uses last value
        expect(progression[4].lightness).to(eq(60))  # uses last value
      end

      it "accepts arrays for saturation values" do
        progression = base_hsl.progression(
          steps: 3,
          lightness: [50, 50, 50],
          saturation: [10, 30, 80],
        )
        expect(progression[0].saturation).to(eq(10))
        expect(progression[1].saturation).to(eq(30))
        expect(progression[2].saturation).to(eq(80))
      end

      it "uses last saturation array value when steps exceed array length" do
        progression = base_hsl.progression(
          steps: 4,
          lightness: [50, 50, 50, 50],
          saturation: [10, 30],
        )
        expect(progression[0].saturation).to(eq(10))
        expect(progression[1].saturation).to(eq(30))
        expect(progression[2].saturation).to(eq(30))  # uses last value
        expect(progression[3].saturation).to(eq(30))  # uses last value
      end

      it "can mix arrays and procs" do
        # Array for lightness, proc for saturation
        progression = base_hsl.progression(
          steps: 3,
          lightness: [20, 50, 80],
          saturation: ->(_hsl, i) { 10 + (i * 20) },
        )
        expect(progression[0].lightness).to(eq(20))
        expect(progression[0].saturation).to(eq(10))
        expect(progression[1].lightness).to(eq(50))
        expect(progression[1].saturation).to(eq(30))
        expect(progression[2].lightness).to(eq(80))
        expect(progression[2].saturation).to(eq(50))
      end

      it "clamps array values to valid ranges" do
        progression = base_hsl.progression(
          steps: 3,
          lightness: [-10, 50, 150],
          saturation: [-5, 50, 120],
        )
        expect(progression[0].lightness).to(eq(0))    # -10 clamped to 0
        expect(progression[0].saturation).to(eq(0))   # -5 clamped to 0
        expect(progression[1].lightness).to(eq(50))   # 50 unchanged
        expect(progression[1].saturation).to(eq(50))  # 50 unchanged
        expect(progression[2].lightness).to(eq(100))  # 150 clamped to 100
        expect(progression[2].saturation).to(eq(100)) # 120 clamped to 100
      end
    end

    describe "error handling" do
      it "raises error for invalid steps" do
        expect do
          base_hsl.progression(steps: 0, lightness: ->(_hsl, _i) { 50 })
        end.to(raise_error(ArgumentError, "steps must be at least 1"))
      end

      it "raises error for invalid lightness type" do
        expect do
          base_hsl.progression(steps: 3, lightness: 50)
        end.to(raise_error(ArgumentError, "lightness must be a proc or array"))
      end

      it "raises error for invalid saturation type" do
        expect do
          base_hsl.progression(steps: 3, lightness: ->(_hsl, _i) { 50 }, saturation: 30)
        end.to(raise_error(ArgumentError, "saturation must be a proc or array"))
      end
    end

    describe "usage examples" do
      it "creates simple black-to-white progression" do
        black_progression = base_hsl.progression(steps: 3, lightness: ->(_hsl, _i) { 0 })
        white_progression = base_hsl.progression(steps: 3, lightness: ->(_hsl, _i) { 100 })

        expect(black_progression.all? { |c| c.lightness == 0 }).to(be(true))
        expect(white_progression.all? { |c| c.lightness == 100 }).to(be(true))
      end

      it "creates linear lightness progression" do
        progression = base_hsl.progression(
          steps: 6,
          lightness: ->(hsl, i) { hsl.lightness + (i * 10) },
        )

        expected_lightness = [50, 60, 70, 80, 90, 100]
        actual_lightness = progression.map(&:lightness)
        expect(actual_lightness).to(eq(expected_lightness))
      end
    end
  end

  describe "#to_ansi" do
    it "delegates to RGB#to_ansi" do
      color = new(hue: 0, saturation: 100, lightness: 50)
      expect(color.to_ansi).to(eq("38;2;255;0;0")) # Pure red
    end

    it "supports background layer" do
      color = new(hue: 0, saturation: 100, lightness: 50)
      expect(color.to_ansi(layer: :background)).to(eq("48;2;255;0;0"))
    end

    it "uses true color for non-standard colors" do
      color = new(hue: 180, saturation: 50, lightness: 50)
      result = color.to_ansi
      expect(result).to(match(/\A38;2;\d+;\d+;\d+\z/))
    end
  end

  describe "alpha channel support" do
    describe "initialization" do
      it "defaults alpha to 100 (fully opaque)" do
        hsl = new(hue: 0, saturation: 100, lightness: 50)
        expect(hsl.alpha.value).to(eq(100.0))
      end

      it "accepts explicit alpha value" do
        hsl = new(hue: 0, saturation: 100, lightness: 50, alpha: 50)
        expect(hsl.alpha.value).to(eq(50.0))
      end
    end

    describe "parsing with alpha" do
      context "with modern format slash separator" do
        it "parses hsl(H S% L% / alpha) format" do
          hsl = parse("hsl(240 50% 75% / 0.5)")
          expect(hsl.hue.value).to(eq(240))
          expect(hsl.saturation.value).to(eq(50.0))
          expect(hsl.lightness.value).to(eq(75.0))
          expect(hsl.alpha.value).to(eq(50.0))
        end

        it "parses hsl(H S% L% / percentage) format" do
          hsl = parse("hsl(240 50% 75% / 50%)")
          expect(hsl.alpha.value).to(eq(50.0))
        end
      end

      context "with legacy hsla format" do
        it "parses hsla(H, S%, L%, alpha) format" do
          hsl = parse("hsla(240, 50%, 75%, 0.5)")
          expect(hsl.hue.value).to(eq(240))
          expect(hsl.saturation.value).to(eq(50.0))
          expect(hsl.lightness.value).to(eq(75.0))
          expect(hsl.alpha.value).to(eq(50.0))
        end

        it "parses comma-separated with alpha" do
          hsl = parse("240, 50%, 75%, 0.75")
          expect(hsl.alpha.value).to(eq(75.0))
        end
      end
    end

    describe "output with alpha" do
      describe "#to_s" do
        it "includes alpha when alpha < 100" do
          hsl = new(hue: 240, saturation: 50, lightness: 75, alpha: 50)
          expect(hsl.to_s).to(include("/ 0.5"))
        end

        it "omits alpha when alpha = 100" do
          hsl = new(hue: 240, saturation: 50, lightness: 75, alpha: 100)
          expect(hsl.to_s).not_to(include("/"))
        end

        it "omits alpha when alpha is default" do
          hsl = new(hue: 240, saturation: 50, lightness: 75)
          expect(hsl.to_s).not_to(include("/"))
        end
      end
    end

    describe "blending with alpha" do
      it "interpolates alpha values" do
        hsl1 = new(hue: 0, saturation: 100, lightness: 50, alpha: 100)
        hsl2 = new(hue: 240, saturation: 100, lightness: 50, alpha: 0)
        blended = hsl1.blend(hsl2, 0.5)
        expect(blended.alpha.value).to(eq(50.0))
      end

      it "blends colors with different alpha" do
        hsl1 = new(hue: 0, saturation: 100, lightness: 50, alpha: 80)
        hsl2 = new(hue: 120, saturation: 100, lightness: 50, alpha: 20)
        blended = hsl1.blend(hsl2, 0.25)
        expect(blended.alpha.value).to(eq(65.0))
      end
    end

    describe "conversions preserve alpha" do
      it "preserves alpha when converting to RGB" do
        hsl = new(hue: 0, saturation: 100, lightness: 50, alpha: 50)
        rgb = hsl.to_rgb
        expect(rgb.alpha.value).to(eq(50.0))
      end

      it "preserves alpha when converting to OKLCH" do
        hsl = new(hue: 0, saturation: 100, lightness: 50, alpha: 75)
        oklch = hsl.to_oklch
        expect(oklch.alpha.value).to(eq(75.0))
      end

      it "preserves alpha through HSL→RGB→HSL conversion" do
        hsl1 = new(hue: 240, saturation: 80, lightness: 60, alpha: 60)
        rgb = hsl1.to_rgb
        hsl2 = rgb.to_hsl
        expect(hsl2.alpha.value).to(eq(60.0))
      end
    end
  end

  describe "#pretty_print" do
    it "outputs standard Ruby format with colored swatch in class name" do
      hsl = new(hue: 240, saturation: 80, lightness: 50)
      io = StringIO.new
      PP.pp(hsl, io)

      output = io.string.chomp
      expect(output).to(include("\x1b["))
      expect(output).to(include("█"))
      expect(output).to(include("#<Unmagic::Color::HSL["))
      expect(output).to(include("@hue=240"))
      expect(output).to(include("@saturation=80"))
      expect(output).to(include("@lightness=50"))
    end

    it "rounds component values" do
      hsl = new(hue: 9.7, saturation: 99.6, lightness: 60.4)
      io = StringIO.new
      PP.pp(hsl, io)

      output = io.string.chomp
      expect(output).to(include("@hue=10"))
      expect(output).to(include("@saturation=100"))
      expect(output).to(include("@lightness=60"))
    end
  end
end
