# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unmagic::Color::HSL do
  describe '.valid?' do
    it 'validates HSL with parentheses' do
      expect(Unmagic::Color::HSL.valid?('hsl(180, 50%, 50%)')).to be true
      expect(Unmagic::Color::HSL.valid?('hsl(0, 0%, 0%)')).to be true
      expect(Unmagic::Color::HSL.valid?('hsl(360, 100%, 100%)')).to be true
    end

    it 'validates HSL without parentheses' do
      expect(Unmagic::Color::HSL.valid?('180, 50%, 50%')).to be true
      expect(Unmagic::Color::HSL.valid?('0, 0%, 0%')).to be true
      expect(Unmagic::Color::HSL.valid?('360, 100%, 100%')).to be true
    end

    it 'validates HSL without percent signs' do
      expect(Unmagic::Color::HSL.valid?('hsl(180, 50, 50)')).to be true
      expect(Unmagic::Color::HSL.valid?('180, 50, 50')).to be true
    end

    it 'validates HSL with decimals' do
      expect(Unmagic::Color::HSL.valid?('hsl(180.5, 50.5%, 50.5%)')).to be true
      expect(Unmagic::Color::HSL.valid?('180.5, 50.5, 50.5')).to be true
    end

    it 'rejects invalid hue values' do
      expect(Unmagic::Color::HSL.valid?('hsl(361, 50%, 50%)')).to be false  # > 360
      expect(Unmagic::Color::HSL.valid?('hsl(-1, 50%, 50%)')).to be false   # < 0
    end

    it 'rejects invalid saturation values' do
      expect(Unmagic::Color::HSL.valid?('hsl(180, 101%, 50%)')).to be false  # > 100
      expect(Unmagic::Color::HSL.valid?('hsl(180, -1%, 50%)')).to be false   # < 0
    end

    it 'rejects invalid lightness values' do
      expect(Unmagic::Color::HSL.valid?('hsl(180, 50%, 101%)')).to be false  # > 100
      expect(Unmagic::Color::HSL.valid?('hsl(180, 50%, -1%)')).to be false   # < 0
    end

    it 'rejects invalid formats' do
      expect(Unmagic::Color::HSL.valid?('hsl(180, 50%)')).to be false # Only 2 values
      expect(Unmagic::Color::HSL.valid?('hsl(180, 50%, 50%, 1)')).to be false  # Too many values
      expect(Unmagic::Color::HSL.valid?('hsl(red, green, blue)')).to be false  # Not numbers
      expect(Unmagic::Color::HSL.valid?('180 50 50')).to be false # No commas
      expect(Unmagic::Color::HSL.valid?('')).to be false
      expect(Unmagic::Color::HSL.valid?(nil)).to be false
      expect(Unmagic::Color::HSL.valid?(123)).to be false
    end
  end

  describe '.parse' do
    it 'parses HSL with parentheses and percents' do
      color = Unmagic::Color::HSL.parse('hsl(180, 50%, 50%)')
      expect(color).to be_a(Unmagic::Color::HSL)
      expect(color.hue).to eq(180)
      expect(color.saturation).to eq(50)
      expect(color.lightness).to eq(50)
    end

    it 'parses HSL without parentheses' do
      color = Unmagic::Color::HSL.parse('180, 50%, 50%')
      expect(color).to be_a(Unmagic::Color::HSL)
      expect(color.hue).to eq(180)
      expect(color.saturation).to eq(50)
      expect(color.lightness).to eq(50)
    end

    it 'parses HSL without percent signs' do
      color = Unmagic::Color::HSL.parse('hsl(180, 50, 50)')
      expect(color.hue).to eq(180)
      expect(color.saturation).to eq(50)
      expect(color.lightness).to eq(50)
    end

    it 'parses HSL with extra spaces' do
      color = Unmagic::Color::HSL.parse('hsl(  180  ,  50%  ,  50%  )')
      expect(color.hue).to eq(180)
      expect(color.saturation).to eq(50)
      expect(color.lightness).to eq(50)
    end

    it 'converts to RGB correctly' do
      # Red
      red = Unmagic::Color::HSL.parse('hsl(0, 100%, 50%)')
      expect(red.red).to eq(255)
      expect(red.green).to eq(0)
      expect(red.blue).to eq(0)

      # Green
      green = Unmagic::Color::HSL.parse('hsl(120, 100%, 50%)')
      expect(green.red).to eq(0)
      expect(green.green).to eq(255)
      expect(green.blue).to eq(0)

      # Blue
      blue = Unmagic::Color::HSL.parse('hsl(240, 100%, 50%)')
      expect(blue.red).to eq(0)
      expect(blue.green).to eq(0)
      expect(blue.blue).to eq(255)

      # Gray
      gray = Unmagic::Color::HSL.parse('hsl(0, 0%, 50%)')
      expect(gray.red).to eq(128)
      expect(gray.green).to eq(128)
      expect(gray.blue).to eq(128)

      # White
      white = Unmagic::Color::HSL.parse('hsl(0, 0%, 100%)')
      expect(white.red).to eq(255)
      expect(white.green).to eq(255)
      expect(white.blue).to eq(255)

      # Black
      black = Unmagic::Color::HSL.parse('hsl(0, 0%, 0%)')
      expect(black.red).to eq(0)
      expect(black.green).to eq(0)
      expect(black.blue).to eq(0)
    end

    it 'handles hue wrapping' do
      color1 = Unmagic::Color::HSL.parse('hsl(0, 100%, 50%)')
      color2 = Unmagic::Color::HSL.parse('hsl(360, 100%, 50%)')
      expect(color1.to_hex).to eq(color2.to_hex)
    end

    it 'returns nil for invalid input' do
      expect(Unmagic::Color::HSL.parse('hsl(180, 50%)')).to be_nil
      expect(Unmagic::Color::HSL.parse('hsl(red, green, blue)')).to be_nil
      expect(Unmagic::Color::HSL.parse('180 50 50')).to be_nil
      expect(Unmagic::Color::HSL.parse('')).to be_nil
      expect(Unmagic::Color::HSL.parse(nil)).to be_nil
      expect(Unmagic::Color::HSL.parse(123)).to be_nil
    end
  end

  describe '#new' do
    it 'creates HSL color with keyword arguments' do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 50, lightness: 50)
      expect(color.hue).to eq(180)
      expect(color.saturation).to eq(50)
      expect(color.lightness).to eq(50)
    end

    it 'wraps hue values' do
      color = Unmagic::Color::HSL.new(hue: 720, saturation: 50, lightness: 50)
      expect(color.hue).to eq(0) # 720 % 360 = 0
    end

    it 'clamps saturation to 0-100' do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 150, lightness: 50)
      expect(color.saturation).to eq(100)
    end

    it 'clamps lightness to 0-100' do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 50, lightness: -50)
      expect(color.lightness).to eq(0)
    end
  end

  describe '#to_hsl' do
    it 'returns itself' do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 50, lightness: 50)
      expect(color.to_hsl).to eq(color)
    end
  end

  describe 'inheritance' do
    it 'inherits from Color' do
      color = Unmagic::Color::HSL.new(hue: 180, saturation: 50, lightness: 50)
      expect(color).to be_a(Unmagic::Color)
      expect(color).to respond_to(:luminance)
      expect(color).to respond_to(:blend)
      expect(color).to respond_to(:contrast_color)
    end

    it 'has RGB values after initialization' do
      color = Unmagic::Color::HSL.new(hue: 0, saturation: 100, lightness: 50)
      expect(color.red).to eq(255)
      expect(color.green).to eq(0)
      expect(color.blue).to eq(0)
    end
  end
end
