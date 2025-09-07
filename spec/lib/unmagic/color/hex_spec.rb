# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unmagic::Color::Hex do
  describe '.valid?' do
    it 'validates hex colors with hash' do
      expect(Unmagic::Color::Hex.valid?('#FF0000')).to be true
      expect(Unmagic::Color::Hex.valid?('#ff0000')).to be true
      expect(Unmagic::Color::Hex.valid?('#F00')).to be true
    end

    it 'validates hex colors without hash' do
      expect(Unmagic::Color::Hex.valid?('FF0000')).to be true
      expect(Unmagic::Color::Hex.valid?('ff0000')).to be true
      expect(Unmagic::Color::Hex.valid?('F00')).to be true
    end

    it 'rejects invalid hex colors' do
      expect(Unmagic::Color::Hex.valid?('#GGGGGG')).to be false
      expect(Unmagic::Color::Hex.valid?('#FF00')).to be false # Wrong length
      expect(Unmagic::Color::Hex.valid?('#FF00000')).to be false # Too long
      expect(Unmagic::Color::Hex.valid?('ZZZ')).to be false
      expect(Unmagic::Color::Hex.valid?('')).to be false
      expect(Unmagic::Color::Hex.valid?(nil)).to be false
      expect(Unmagic::Color::Hex.valid?(123)).to be false
    end

    it 'handles whitespace' do
      expect(Unmagic::Color::Hex.valid?('  #FF0000  ')).to be true
      expect(Unmagic::Color::Hex.valid?('  FF0000  ')).to be true
    end
  end

  describe '.parse' do
    it 'parses 6-character hex with hash' do
      color = Unmagic::Color::Hex.parse('#FF8040')
      expect(color).to be_a(Unmagic::Color::Hex)
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'parses 6-character hex without hash' do
      color = Unmagic::Color::Hex.parse('FF8040')
      expect(color).to be_a(Unmagic::Color::Hex)
      expect(color.red).to eq(255)
      expect(color.green).to eq(128)
      expect(color.blue).to eq(64)
    end

    it 'parses 3-character hex codes' do
      color = Unmagic::Color::Hex.parse('#F84')
      expect(color).to be_a(Unmagic::Color::Hex)
      expect(color.red).to eq(255)
      expect(color.green).to eq(136)
      expect(color.blue).to eq(68)
    end

    it 'parses 3-character hex without hash' do
      color = Unmagic::Color::Hex.parse('F84')
      expect(color).to be_a(Unmagic::Color::Hex)
      expect(color.red).to eq(255)
      expect(color.green).to eq(136)
      expect(color.blue).to eq(68)
    end

    it 'handles lowercase hex' do
      color = Unmagic::Color::Hex.parse('#aabbcc')
      expect(color.red).to eq(170)
      expect(color.green).to eq(187)
      expect(color.blue).to eq(204)
    end

    it 'handles mixed case' do
      color = Unmagic::Color::Hex.parse('#AaBbCc')
      expect(color.red).to eq(170)
      expect(color.green).to eq(187)
      expect(color.blue).to eq(204)
    end

    it 'returns nil for invalid input' do
      expect(Unmagic::Color::Hex.parse('#GGGGGG')).to be_nil
      expect(Unmagic::Color::Hex.parse('#FF00')).to be_nil
      expect(Unmagic::Color::Hex.parse('FFFFF')).to be_nil # 5 chars
      expect(Unmagic::Color::Hex.parse('')).to be_nil
      expect(Unmagic::Color::Hex.parse(nil)).to be_nil
      expect(Unmagic::Color::Hex.parse(123)).to be_nil
    end

    it 'handles whitespace' do
      color = Unmagic::Color::Hex.parse('  #FF0000  ')
      expect(color).to be_a(Unmagic::Color::Hex)
      expect(color.to_hex).to eq('#ff0000')
    end
  end

  describe 'inheritance' do
    it 'inherits from Color' do
      color = Unmagic::Color::Hex.parse('#FF0000')
      expect(color).to be_a(Unmagic::Color)
      expect(color).to respond_to(:luminance)
      expect(color).to respond_to(:blend)
      expect(color).to respond_to(:contrast_color)
    end
  end
end
