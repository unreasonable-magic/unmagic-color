# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unmagic::Color do
  describe '.parse' do
    it 'parses hex colors with hash' do
      color = Unmagic::Color.parse('#FF0000')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.to_hex).to eq('#ff0000')
    end

    it 'parses hex colors without hash' do
      color = Unmagic::Color.parse('FF0000')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.to_hex).to eq('#ff0000')
    end

    it 'parses 3-character hex codes' do
      color = Unmagic::Color.parse('#F00')
      expect(color).to be_a(Unmagic::Color::RGB)
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

    it 'returns existing color instance unchanged' do
      original = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      parsed = Unmagic::Color.parse(original)
      expect(parsed).to be(original)
    end

    it 'raises ParseError for nil input' do
      expect { Unmagic::Color.parse(nil) }.to raise_error(Unmagic::Color::ParseError, "Can't pass nil as a color")
    end

    it 'raises ParseError for empty string' do
      expect { Unmagic::Color.parse('') }.to raise_error(Unmagic::Color::ParseError, "Can't parse empty string")
      expect { Unmagic::Color.parse('   ') }.to raise_error(Unmagic::Color::ParseError, "Can't parse empty string")
    end

    it 'raises ParseError for unknown color format' do
      expect { Unmagic::Color.parse('invalid') }.to raise_error(Unmagic::Color::ParseError, 'Unknown color "invalid"')
      expect { Unmagic::Color.parse('rainbow') }.to raise_error(Unmagic::Color::ParseError, 'Unknown color "rainbow"')
    end

    it 'lets RGB parsing errors bubble up' do
      expect { Unmagic::Color.parse('rgb(255)') }.to raise_error(Unmagic::Color::RGB::ParseError, /Expected 3 RGB values, got 1/)
      expect { Unmagic::Color.parse('rgb(255, abc, 0)') }.to raise_error(Unmagic::Color::RGB::ParseError, /Invalid green value: "abc"/)
    end

    it 'lets hex parsing errors bubble up' do
      expect { Unmagic::Color.parse('#FFFF') }.to raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid number of characters/)
      expect { Unmagic::Color.parse('#GGGGGG') }.to raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid hex characters: G/)
    end

    it 'lets HSL parsing errors bubble up' do
      expect { Unmagic::Color.parse('hsl(180, 50%)') }.to raise_error(Unmagic::Color::HSL::ParseError, /Expected 3 HSL values, got 2/)
      expect { Unmagic::Color.parse('hsl(abc, 50%, 50%)') }.to raise_error(Unmagic::Color::HSL::ParseError, /Invalid hue value: "abc"/)
      expect { Unmagic::Color.parse('hsl(180, 150%, 50%)') }.to raise_error(Unmagic::Color::HSL::ParseError, /Saturation must be between 0 and 100, got 150/)
    end

    it 'lets OKLCH parsing errors bubble up' do
      expect { Unmagic::Color.parse('oklch(0.5 0.2)') }.to raise_error(Unmagic::Color::OKLCH::ParseError, /Expected 3 OKLCH values, got 2/)
      expect { Unmagic::Color.parse('oklch(abc 0.2 180)') }.to raise_error(Unmagic::Color::OKLCH::ParseError, /Invalid lightness value: "abc"/)
      expect { Unmagic::Color.parse('oklch(1.5 0.2 180)') }.to raise_error(Unmagic::Color::OKLCH::ParseError, /Lightness must be between 0 and 1, got 1.5/)
    end

    it 'handles whitespace around valid colors' do
      color = Unmagic::Color.parse('  #FF0000  ')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.to_hex).to eq('#ff0000')
    end
  end

  describe '.[]' do
    it 'works as alias for parse' do
      color = Unmagic::Color['#FF0000']
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.to_hex).to eq('#ff0000')
    end

    it 'returns existing color instance unchanged' do
      original = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      result = Unmagic::Color[original]
      expect(result).to be(original)
    end

    it 'raises ParseError for invalid input' do
      expect { Unmagic::Color['invalid'] }.to raise_error(Unmagic::Color::ParseError)
    end
  end
end

RSpec.describe Unmagic::Color::RGB do
  describe '#to_hex' do
    it 'converts to lowercase hex string' do
      color = Unmagic::Color::RGB.new(red: 255, green: 128, blue: 64)
      expect(color.to_hex).to eq('#ff8040')
    end

    it 'pads with zeros' do
      color = Unmagic::Color::RGB.new(red: 1, green: 2, blue: 3)
      expect(color.to_hex).to eq('#010203')
    end
  end

  describe '#to_rgb' do
    it 'returns an RGB instance' do
      color = Unmagic::Color::RGB.new(red: 100, green: 150, blue: 200)
      rgb = color.to_rgb
      expect(rgb).to be_a(Unmagic::Color::RGB)
      expect(rgb.red).to eq(100)
      expect(rgb.green).to eq(150)
      expect(rgb.blue).to eq(200)
    end
  end

  describe '#to_hsl' do
    it 'converts red to HSL' do
      color = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      hsl = color.to_hsl
      expect(hsl).to be_a(Unmagic::Color::HSL)
      expect(hsl.hue).to eq(0)
      expect(hsl.saturation).to eq(100)
      expect(hsl.lightness).to eq(50)
    end

    it 'converts gray to HSL' do
      color = Unmagic::Color::RGB.new(red: 128, green: 128, blue: 128)
      hsl = color.to_hsl
      expect(hsl.hue).to eq(0)
      expect(hsl.saturation).to eq(0)
      expect(hsl.lightness).to eq(50)
    end
  end

  describe '#luminance' do
    it 'calculates luminance for white' do
      color = Unmagic::Color::RGB.new(red: 255, green: 255, blue: 255)
      expect(color.luminance).to be_within(0.001).of(1.0)
    end

    it 'calculates luminance for black' do
      color = Unmagic::Color::RGB.new(red: 0, green: 0, blue: 0)
      expect(color.luminance).to be_within(0.001).of(0.0)
    end

    it 'calculates luminance for mid-gray' do
      color = Unmagic::Color::RGB.new(red: 128, green: 128, blue: 128)
      expect(color.luminance).to be_within(0.01).of(0.216)
    end
  end

  describe '#light? and #dark?' do
    it 'identifies light colors' do
      color = Unmagic::Color::RGB.new(red: 255, green: 255, blue: 200)
      expect(color.light?).to be true
      expect(color.dark?).to be false
    end

    it 'identifies dark colors' do
      color = Unmagic::Color::RGB.new(red: 50, green: 50, blue: 50)
      expect(color.light?).to be false
      expect(color.dark?).to be true
    end
  end


  describe '#blend' do
    it 'blends two colors equally' do
      red = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      blue = Unmagic::Color::RGB.new(red: 0, green: 0, blue: 255)
      purple = red.blend(blue, 0.5)
      expect(purple.red).to eq(128)
      expect(purple.green).to eq(0)
      expect(purple.blue).to eq(128)
    end

    it 'returns first color with 0 amount' do
      red = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      blue = Unmagic::Color::RGB.new(red: 0, green: 0, blue: 255)
      result = red.blend(blue, 0)
      expect(result.to_hex).to eq('#ff0000')
    end

    it 'returns second color with 1 amount' do
      red = Unmagic::Color::RGB.new(red: 255, green: 0, blue: 0)
      blue = Unmagic::Color::RGB.new(red: 0, green: 0, blue: 255)
      result = red.blend(blue, 1)
      expect(result.to_hex).to eq('#0000ff')
    end
  end

  describe '#lighten' do
    it 'lightens a color' do
      color = Unmagic::Color::RGB.new(red: 100, green: 100, blue: 100)
      lighter = color.lighten(0.2)
      expect(lighter.red).to be > 100
      expect(lighter.green).to be > 100
      expect(lighter.blue).to be > 100
    end

    it "doesn't exceed 255" do
      color = Unmagic::Color::RGB.new(red: 250, green: 250, blue: 250)
      lighter = color.lighten(0.5)
      expect(lighter.red).to eq(253)
      expect(lighter.green).to eq(253)
      expect(lighter.blue).to eq(253)
    end
  end

  describe '#darken' do
    it 'darkens a color' do
      color = Unmagic::Color::RGB.new(red: 200, green: 200, blue: 200)
      darker = color.darken(0.2)
      expect(darker.red).to be < 200
      expect(darker.green).to be < 200
      expect(darker.blue).to be < 200
    end

    it "doesn't go below 0" do
      color = Unmagic::Color::RGB.new(red: 10, green: 10, blue: 10)
      darker = color.darken(0.9)
      expect(darker.red).to be >= 0
      expect(darker.green).to be >= 0
      expect(darker.blue).to be >= 0
    end
  end


  describe '#==' do
    it 'compares colors by RGB values' do
      color1 = Unmagic::Color::RGB.new(red: 100, green: 150, blue: 200)
      color2 = Unmagic::Color::RGB.new(red: 100, green: 150, blue: 200)
      color3 = Unmagic::Color::RGB.new(red: 100, green: 150, blue: 201)

      expect(color1).to eq(color2)
      expect(color1).not_to eq(color3)
    end

    it 'returns false for non-Color objects' do
      color = Unmagic::Color::RGB.new(red: 100, green: 150, blue: 200)
      expect(color).not_to eq('#6496c8')
      expect(color).not_to eq(nil)
      expect(color).not_to eq([ 100, 150, 200 ])
    end
  end

  describe '#to_s' do
    it 'returns hex representation' do
      color = Unmagic::Color::RGB.new(red: 255, green: 128, blue: 0)
      expect(color.to_s).to eq('#ff8000')
    end
  end

  describe 'value clamping' do
    it 'clamps values above 255' do
      color = Unmagic::Color::RGB.new(red: 300, green: 500, blue: 1000)
      expect(color.red).to eq(255)
      expect(color.green).to eq(255)
      expect(color.blue).to eq(255)
    end

    it 'clamps negative values to 0' do
      color = Unmagic::Color::RGB.new(red: -10, green: -50, blue: -100)
      expect(color.red).to eq(0)
      expect(color.green).to eq(0)
      expect(color.blue).to eq(0)
    end

    it 'converts string values' do
      color = Unmagic::Color::RGB.new(red: '100', green: '150', blue: '200')
      expect(color.red).to eq(100)
      expect(color.green).to eq(150)
      expect(color.blue).to eq(200)
    end
  end
end
