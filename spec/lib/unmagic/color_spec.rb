# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unmagic::Color do
  describe '.parse' do
    it 'parses hex colors with hash' do
      color = Unmagic::Color.parse('#FF0000')
      expect(color).to be_a(Unmagic::Color::RGB::Hex)
      expect(color.to_hex).to eq('#ff0000')
    end

    it 'parses hex colors without hash' do
      color = Unmagic::Color.parse('FF0000')
      expect(color).to be_a(Unmagic::Color::RGB::Hex)
      expect(color.to_hex).to eq('#ff0000')
    end

    it 'parses 3-character hex codes' do
      color = Unmagic::Color.parse('#F00')
      expect(color).to be_a(Unmagic::Color::RGB::Hex)
      expect(color.to_hex).to eq('#ff0000')
    end

    it 'parses RGB format with parentheses' do
      color = Unmagic::Color.parse('rgb(255, 128, 0)')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(0)
    end

    it 'parses HSL format' do
      color = Unmagic::Color.parse('hsl(0, 100%, 50%)')
      expect(color).to be_a(Unmagic::Color::HSL)
      rgb = color.to_rgb
      expect(rgb.red).to eq(255)
      expect(rgb.green).to eq(0)
      expect(rgb.blue).to eq(0)
    end

    it 'returns nil for invalid input' do
      expect(Unmagic::Color.parse('invalid')).to be_nil
      expect(Unmagic::Color.parse('')).to be_nil
      expect(Unmagic::Color.parse(nil)).to be_nil
      expect(Unmagic::Color.parse(123)).to be_nil
    end

    it 'handles whitespace' do
      color = Unmagic::Color.parse('  #FF0000  ')
      expect(color).to be_a(Unmagic::Color::RGB::Hex)
      expect(color.to_hex).to eq('#ff0000')
    end
  end

  describe '#to_hex' do
    it 'converts to lowercase hex string' do
      color = Unmagic::Color.new(red: 255, green: 128, blue: 64)
      expect(color.to_hex).to eq('#ff8040')
    end

    it 'pads with zeros' do
      color = Unmagic::Color.new(red: 1, green: 2, blue: 3)
      expect(color.to_hex).to eq('#010203')
    end
  end

  describe '#to_rgb' do
    it 'returns an RGB instance' do
      color = Unmagic::Color.new(red: 100, green: 150, blue: 200)
      rgb = color.to_rgb
      expect(rgb).to be_a(Unmagic::Color::RGB)
      expect(rgb.red).to eq(100)
      expect(rgb.green).to eq(150)
      expect(rgb.blue).to eq(200)
    end
  end

  describe '#to_hsl' do
    it 'converts red to HSL' do
      color = Unmagic::Color.new(red: 255, green: 0, blue: 0)
      hsl = color.to_hsl
      expect(hsl).to be_a(Unmagic::Color::HSL)
      expect(hsl.hue).to eq(0)
      expect(hsl.saturation).to eq(100)
      expect(hsl.lightness).to eq(50)
    end

    it 'converts gray to HSL' do
      color = Unmagic::Color.new(red: 128, green: 128, blue: 128)
      hsl = color.to_hsl
      expect(hsl.hue).to eq(0)
      expect(hsl.saturation).to eq(0)
      expect(hsl.lightness).to eq(50)
    end
  end

  describe '#luminance' do
    it 'calculates luminance for white' do
      color = Unmagic::Color.new(red: 255, green: 255, blue: 255)
      expect(color.luminance).to be_within(0.001).of(1.0)
    end

    it 'calculates luminance for black' do
      color = Unmagic::Color.new(red: 0, green: 0, blue: 0)
      expect(color.luminance).to be_within(0.001).of(0.0)
    end

    it 'calculates luminance for mid-gray' do
      color = Unmagic::Color.new(red: 128, green: 128, blue: 128)
      expect(color.luminance).to be_within(0.01).of(0.216)
    end
  end

  describe '#light? and #dark?' do
    it 'identifies light colors' do
      color = Unmagic::Color.new(red: 255, green: 255, blue: 200)
      expect(color.light?).to be true
      expect(color.dark?).to be false
    end

    it 'identifies dark colors' do
      color = Unmagic::Color.new(red: 50, green: 50, blue: 50)
      expect(color.light?).to be false
      expect(color.dark?).to be true
    end
  end

  describe '#contrast_color' do
    it 'returns black for light colors' do
      color = Unmagic::Color.new(red: 255, green: 255, blue: 200)
      contrast = color.contrast_color
      expect(contrast.to_hex).to eq('#000000')
    end

    it 'returns white for dark colors' do
      color = Unmagic::Color.new(red: 50, green: 50, blue: 50)
      contrast = color.contrast_color
      expect(contrast.to_hex).to eq('#ffffff')
    end
  end

  describe '#contrast_ratio' do
    it 'calculates maximum contrast ratio' do
      white = Unmagic::Color.new(red: 255, green: 255, blue: 255)
      black = Unmagic::Color.new(red: 0, green: 0, blue: 0)
      expect(white.contrast_ratio(black)).to be_within(0.1).of(21.0)
    end

    it 'calculates minimum contrast ratio' do
      color = Unmagic::Color.new(red: 128, green: 128, blue: 128)
      expect(color.contrast_ratio(color)).to eq(1.0)
    end

    it 'accepts string colors' do
      color = Unmagic::Color.new(red: 255, green: 255, blue: 255)
      ratio = color.contrast_ratio('#000000')
      expect(ratio).to be_within(0.1).of(21.0)
    end
  end

  describe '#blend' do
    it 'blends two colors equally' do
      red = Unmagic::Color.new(red: 255, green: 0, blue: 0)
      blue = Unmagic::Color.new(red: 0, green: 0, blue: 255)
      purple = red.blend(blue, 0.5)
      expect(purple.red).to eq(128)
      expect(purple.green).to eq(0)
      expect(purple.blue).to eq(128)
    end

    it 'returns first color with 0 amount' do
      red = Unmagic::Color.new(red: 255, green: 0, blue: 0)
      blue = Unmagic::Color.new(red: 0, green: 0, blue: 255)
      result = red.blend(blue, 0)
      expect(result.to_hex).to eq('#ff0000')
    end

    it 'returns second color with 1 amount' do
      red = Unmagic::Color.new(red: 255, green: 0, blue: 0)
      blue = Unmagic::Color.new(red: 0, green: 0, blue: 255)
      result = red.blend(blue, 1)
      expect(result.to_hex).to eq('#0000ff')
    end
  end

  describe '#lighten' do
    it 'lightens a color' do
      color = Unmagic::Color.new(red: 100, green: 100, blue: 100)
      lighter = color.lighten(0.2)
      expect(lighter.red).to be > 100
      expect(lighter.green).to be > 100
      expect(lighter.blue).to be > 100
    end

    it "doesn't exceed 255" do
      color = Unmagic::Color.new(red: 250, green: 250, blue: 250)
      lighter = color.lighten(0.5)
      expect(lighter.red).to eq(253)
      expect(lighter.green).to eq(253)
      expect(lighter.blue).to eq(253)
    end
  end

  describe '#darken' do
    it 'darkens a color' do
      color = Unmagic::Color.new(red: 200, green: 200, blue: 200)
      darker = color.darken(0.2)
      expect(darker.red).to be < 200
      expect(darker.green).to be < 200
      expect(darker.blue).to be < 200
    end

    it "doesn't go below 0" do
      color = Unmagic::Color.new(red: 10, green: 10, blue: 10)
      darker = color.darken(0.9)
      expect(darker.red).to be >= 0
      expect(darker.green).to be >= 0
      expect(darker.blue).to be >= 0
    end
  end

  describe '#adjust_for_contrast' do
    it 'lightens dark colors on dark backgrounds' do
      color = Unmagic::Color.new(red: 50, green: 50, blue: 50)
      background = Unmagic::Color.new(red: 30, green: 30, blue: 30)
      adjusted = color.adjust_for_contrast(background)
      expect(adjusted.luminance).to be > color.luminance
    end

    it 'darkens light colors on light backgrounds' do
      color = Unmagic::Color.new(red: 200, green: 200, blue: 200)
      background = Unmagic::Color.new(red: 250, green: 250, blue: 250)
      adjusted = color.adjust_for_contrast(background)
      expect(adjusted.luminance).to be < color.luminance
    end

    it 'returns original if contrast is sufficient' do
      white = Unmagic::Color.new(red: 255, green: 255, blue: 255)
      black = Unmagic::Color.new(red: 0, green: 0, blue: 0)
      adjusted = white.adjust_for_contrast(black)
      expect(adjusted).to eq(white)
    end

    it 'accepts string backgrounds' do
      color = Unmagic::Color.new(red: 128, green: 128, blue: 128)
      adjusted = color.adjust_for_contrast('#000000')
      expect(adjusted).to be_a(Unmagic::Color::RGB)
    end
  end

  describe '#==' do
    it 'compares colors by RGB values' do
      color1 = Unmagic::Color.new(red: 100, green: 150, blue: 200)
      color2 = Unmagic::Color.new(red: 100, green: 150, blue: 200)
      color3 = Unmagic::Color.new(red: 100, green: 150, blue: 201)

      expect(color1).to eq(color2)
      expect(color1).not_to eq(color3)
    end

    it 'returns false for non-Color objects' do
      color = Unmagic::Color.new(red: 100, green: 150, blue: 200)
      expect(color).not_to eq('#6496c8')
      expect(color).not_to eq(nil)
      expect(color).not_to eq([ 100, 150, 200 ])
    end
  end

  describe '#to_s' do
    it 'returns hex representation' do
      color = Unmagic::Color.new(red: 255, green: 128, blue: 0)
      expect(color.to_s).to eq('#ff8000')
    end
  end

  describe 'value clamping' do
    it 'clamps values above 255' do
      color = Unmagic::Color.new(red: 300, green: 500, blue: 1000)
      expect(color.red).to eq(255)
      expect(color.green).to eq(255)
      expect(color.blue).to eq(255)
    end

    it 'clamps negative values to 0' do
      color = Unmagic::Color.new(red: -10, green: -50, blue: -100)
      expect(color.red).to eq(0)
      expect(color.green).to eq(0)
      expect(color.blue).to eq(0)
    end

    it 'converts string values' do
      color = Unmagic::Color.new(red: '100', green: '150', blue: '200')
      expect(color.red).to eq(100)
      expect(color.green).to eq(150)
      expect(color.blue).to eq(200)
    end
  end
end
