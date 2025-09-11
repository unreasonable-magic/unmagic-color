# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unmagic::Color::RGB do
  describe '.parse' do
    it 'raises ParseError for invalid RGB values' do
      expect { Unmagic::Color::RGB.parse('rgb(255)') }.to raise_error(Unmagic::Color::RGB::ParseError, 'Expected 3 RGB values, got 1')
      expect { Unmagic::Color::RGB.parse('rgb(255, abc, 0)') }.to raise_error(Unmagic::Color::RGB::ParseError, 'Invalid green value: "abc" (must be a number)')
      expect { Unmagic::Color::RGB.parse('rgb(255, 128, def)') }.to raise_error(Unmagic::Color::RGB::ParseError, 'Invalid blue value: "def" (must be a number)')
    end

    it 'raises ParseError for non-string input' do
      expect { Unmagic::Color::RGB.parse(123) }.to raise_error(Unmagic::Color::RGB::ParseError, 'Input must be a string')
      expect { Unmagic::Color::RGB.parse(nil) }.to raise_error(Unmagic::Color::RGB::ParseError, 'Input must be a string')
    end

    it 'lets hex parsing errors bubble up' do
      expect { Unmagic::Color::RGB.parse('#FFFF') }.to raise_error(Unmagic::Color::RGB::Hex::ParseError, /Invalid number of characters/)
    end
  end

  describe '.valid?' do
    it 'validates RGB with parentheses' do
      expect(Unmagic::Color::RGB.valid?('rgb(255, 128, 0)')).to be true
      expect(Unmagic::Color::RGB.valid?('rgb(0, 0, 0)')).to be true
      expect(Unmagic::Color::RGB.valid?('rgb(255, 255, 255)')).to be true
    end

    it 'validates RGB without parentheses' do
      expect(Unmagic::Color::RGB.valid?('255, 128, 0')).to be true
      expect(Unmagic::Color::RGB.valid?('0, 0, 0')).to be true
      expect(Unmagic::Color::RGB.valid?('255, 255, 255')).to be true
    end

    it 'validates RGB with extra spaces' do
      expect(Unmagic::Color::RGB.valid?('rgb( 255 , 128 , 0 )')).to be true
      expect(Unmagic::Color::RGB.valid?('255 , 128 , 0')).to be true
    end

    it 'accepts values outside 0-255 (they get clamped)' do
      expect(Unmagic::Color::RGB.valid?('rgb(256, 128, 0)')).to be true
      expect(Unmagic::Color::RGB.valid?('rgb(-1, 128, 0)')).to be true
      expect(Unmagic::Color::RGB.valid?('300, 128, 0')).to be true
    end

    it 'rejects invalid formats' do
      expect(Unmagic::Color::RGB.valid?('rgb(255, 128)')).to be false # Only 2 values
      expect(Unmagic::Color::RGB.valid?('rgb(255, 128, 0, 1)')).to be false # Too many values
      expect(Unmagic::Color::RGB.valid?('rgb(red, green, blue)')).to be false # Not numbers
      expect(Unmagic::Color::RGB.valid?('255 128 0')).to be false # No commas
      expect(Unmagic::Color::RGB.valid?('')).to be false
      expect(Unmagic::Color::RGB.valid?(nil)).to be false
      expect(Unmagic::Color::RGB.valid?(123)).to be false
    end

    it 'rejects decimal values' do
      expect(Unmagic::Color::RGB.valid?('rgb(255.5, 128, 0)')).to be false
      expect(Unmagic::Color::RGB.valid?('255.0, 128.5, 0.9')).to be false
    end

    it 'validates hex colors with hash' do
      expect(Unmagic::Color::RGB.valid?('#FF0000')).to be true
      expect(Unmagic::Color::RGB.valid?('#ff0000')).to be true
      expect(Unmagic::Color::RGB.valid?('#F00')).to be true
    end

    it 'validates hex colors without hash' do
      expect(Unmagic::Color::RGB.valid?('FF0000')).to be true
      expect(Unmagic::Color::RGB.valid?('ff0000')).to be true
      expect(Unmagic::Color::RGB.valid?('F00')).to be true
    end

    it 'rejects invalid hex colors' do
      expect(Unmagic::Color::RGB.valid?('#GGGGGG')).to be false
      expect(Unmagic::Color::RGB.valid?('#FF00')).to be false # Wrong length
      expect(Unmagic::Color::RGB.valid?('#FF00000')).to be false # Too long
      expect(Unmagic::Color::RGB.valid?('ZZZ')).to be false
    end

    it 'handles whitespace in hex colors' do
      expect(Unmagic::Color::RGB.valid?('  #FF0000  ')).to be true
      expect(Unmagic::Color::RGB.valid?('  FF0000  ')).to be true
    end
  end

  describe '.parse' do
    it 'parses RGB with parentheses' do
      color = Unmagic::Color::RGB.parse('rgb(255, 128, 64)')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'parses RGB without parentheses' do
      color = Unmagic::Color::RGB.parse('255, 128, 64')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'parses RGB with extra spaces' do
      color = Unmagic::Color::RGB.parse('rgb(  255  ,  128  ,  64  )')
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'parses RGB with no spaces' do
      color = Unmagic::Color::RGB.parse('rgb(255,128,64)')
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'clamps values outside 0-255' do
      color = Unmagic::Color::RGB.parse('rgb(300, -50, 128)')
      expect(color.red).to eq(255) # Clamped to 255
      expect(color.green).to eq(0) # Clamped to 0
      expect(color.blue).to eq(128)
    end

    it 'parses 6-character hex with hash' do
      color = Unmagic::Color::RGB.parse('#FF8040')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'parses 6-character hex without hash' do
      color = Unmagic::Color::RGB.parse('FF8040')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'parses 3-character hex codes' do
      color = Unmagic::Color::RGB.parse('#F84')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.red).to eq(255)
      expect(color.green).to eq(136)
      expect(color.blue).to eq(68)
    end

    it 'parses 3-character hex without hash' do
      color = Unmagic::Color::RGB.parse('F84')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.red).to eq(255)
      expect(color.green).to eq(136)
      expect(color.blue).to eq(68)
    end

    it 'handles lowercase hex' do
      color = Unmagic::Color::RGB.parse('#aabbcc')
      expect(color.red).to eq(170)
      expect(color.green).to eq(187)
      expect(color.blue).to eq(204)
    end

    it 'handles mixed case hex' do
      color = Unmagic::Color::RGB.parse('#AaBbCc')
      expect(color.red).to eq(170)
      expect(color.green).to eq(187)
      expect(color.blue).to eq(204)
    end

    it 'handles whitespace in hex' do
      color = Unmagic::Color::RGB.parse('  #FF0000  ')
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color.to_hex).to eq('#ff0000')
    end

    it 'raises ParseError for invalid input' do
      expect { Unmagic::Color::RGB.parse('rgb(255, 128)') }.to raise_error(Unmagic::Color::RGB::ParseError)
      expect { Unmagic::Color::RGB.parse('rgb(red, green, blue)') }.to raise_error(Unmagic::Color::RGB::ParseError)
      expect { Unmagic::Color::RGB.parse('255 128 0') }.to raise_error(Unmagic::Color::RGB::ParseError)
      expect { Unmagic::Color::RGB.parse('#GGGGGG') }.to raise_error(Unmagic::Color::RGB::Hex::ParseError)
      expect { Unmagic::Color::RGB.parse('#FF00') }.to raise_error(Unmagic::Color::RGB::Hex::ParseError)
      expect { Unmagic::Color::RGB.parse('FFFFF') }.to raise_error(Unmagic::Color::RGB::Hex::ParseError) # 5 chars
      expect { Unmagic::Color::RGB.parse('') }.to raise_error(Unmagic::Color::RGB::ParseError)
      expect { Unmagic::Color::RGB.parse(nil) }.to raise_error(Unmagic::Color::RGB::ParseError)
      expect { Unmagic::Color::RGB.parse(123) }.to raise_error(Unmagic::Color::RGB::ParseError)
    end
  end

  describe '#new' do
    it 'creates RGB color with keyword arguments' do
      color = Unmagic::Color::RGB.new(red: 100, green: 150, blue: 200)
      expect(color.red).to eq(100)
      expect(color.green).to eq(150)
      expect(color.blue).to eq(200)
    end

    it 'clamps values to 0-255' do
      color = Unmagic::Color::RGB.new(red: -50, green: 300, blue: 1000)
      expect(color.red).to eq(0)
      expect(color.green).to eq(255)
      expect(color.blue).to eq(255)
    end
  end

  describe 'methods' do
    it 'has expected methods' do
      color = Unmagic::Color::RGB.new(red: 100, green: 150, blue: 200)
      expect(color).to be_a(Unmagic::Color::RGB)
      expect(color).to respond_to(:luminance)
      expect(color).to respond_to(:blend)
      expect(color.to_hex).to eq('#6496c8')
    end
  end
end
