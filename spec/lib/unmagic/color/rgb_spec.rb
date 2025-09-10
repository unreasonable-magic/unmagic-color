# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unmagic::Color::RGB do
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

    it 'rejects values outside 0-255' do
      expect(Unmagic::Color::RGB.valid?('rgb(256, 128, 0)')).to be false
      expect(Unmagic::Color::RGB.valid?('rgb(-1, 128, 0)')).to be false
      expect(Unmagic::Color::RGB.valid?('300, 128, 0')).to be false
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

    it 'returns nil for invalid input' do
      expect(Unmagic::Color::RGB.parse('rgb(255, 128)')).to be_nil
      expect(Unmagic::Color::RGB.parse('rgb(red, green, blue)')).to be_nil
      expect(Unmagic::Color::RGB.parse('255 128 0')).to be_nil
      expect(Unmagic::Color::RGB.parse('')).to be_nil
      expect(Unmagic::Color::RGB.parse(nil)).to be_nil
      expect(Unmagic::Color::RGB.parse(123)).to be_nil
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
      expect(color).to respond_to(:contrast_color)
      expect(color.to_hex).to eq('#6496c8')
    end
  end
end
