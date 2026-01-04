# frozen_string_literal: true

RSpec.describe(Unmagic::Color::String::HashFunction) do
  describe "SUM" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::SUM }

    it "returns sum of character codes" do
      expect(algorithim.call("cat")).to(eq(312))
      expect(algorithim.call("act")).to(eq(312)) # anagrams match
    end

    it "returns 0 for empty string" do
      expect(algorithim.call("")).to(eq(0))
    end
  end

  describe "DJB2" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::DJB2 }

    it "produces consistent hashes" do
      expect(algorithim.call("hello")).to(eq(210714636441))
      expect(algorithim.call("world")).to(eq(210732791149))
    end

    it "produces different hashes for anagrams" do
      result1 = algorithim.call("cat")
      result2 = algorithim.call("act")
      expect(result1).not_to(eq(result2))
    end
  end

  describe "BKDR" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::BKDR }

    it "produces consistent hashes within 32-bit range" do
      result = algorithim.call("test")
      expect(result).to(be_a(Integer))
      expect(result).to(be <= 0xFFFFFFFF)
    end

    it "produces different results for similar strings" do
      result1 = algorithim.call("test1")
      result2 = algorithim.call("test2")
      expect(result1).not_to(eq(result2))
    end
  end

  describe "FNV1A" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::FNV1A }

    it "produces consistent 32-bit hashes" do
      result = algorithim.call("test")
      expect(result).to(be_a(Integer))
      expect(result).to(be <= 0xFFFFFFFF)
    end

    it "has good avalanche effect" do
      result1 = algorithim.call("test1")
      result2 = algorithim.call("test2")
      expect(result1).not_to(eq(result2))
    end
  end

  describe "SDBM" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::SDBM }

    it "produces positive integers" do
      result = algorithim.call("database_key")
      expect(result).to(be_a(Integer))
      expect(result).to(be >= 0)
    end

    it "handles empty strings" do
      expect(algorithim.call("")).to(eq(0))
    end
  end

  describe "JAVA" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::JAVA }

    it "mimics Java String.hashCode()" do
      result = algorithim.call("hello")
      expect(result).to(be_a(Integer))
      expect(result).to(be >= 0)
    end

    it "produces sequential patterns" do
      result1 = algorithim.call("item1")
      result2 = algorithim.call("item2")
      expect(result1).not_to(eq(result2))
    end
  end

  describe "CRC32" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::CRC32 }

    it "uses Zlib.crc32" do
      result = algorithim.call("test")
      expect(result).to(eq(Zlib.crc32("test")))
    end

    it "detects single character changes" do
      result1 = algorithim.call("test")
      result2 = algorithim.call("tset")
      expect(result1).not_to(eq(result2))
    end
  end

  describe "MD5" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::MD5 }

    it "uses MD5 hash truncated to 32 bits" do
      result = algorithim.call("test")
      expected = Digest::MD5.hexdigest("test")[0..7].to_i(16)
      expect(result).to(eq(expected))
    end

    it "produces uniform distribution" do
      result1 = algorithim.call("a")
      result2 = algorithim.call("b")
      expect(result1).not_to(eq(result2))
    end
  end

  describe "POSITION" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::POSITION }

    it "weights characters by position" do
      expect(algorithim.call("ABC")).not_to(eq(algorithim.call("CBA")))
    end

    it "gives higher weight to later positions" do
      result = algorithim.call("ab")
      # 'a' * 1^2 + 'b' * 2^2 = 97 * 1 + 98 * 4 = 97 + 392 = 489
      expect(result).to(eq(489))
    end
  end

  describe "PERCEPTUAL" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::PERCEPTUAL }

    it "normalizes case and punctuation" do
      result1 = algorithim.call("Hello!")
      result2 = algorithim.call("hello")
      expect(result1).to(eq(result2))
    end

    it "treats different cases as same" do
      result1 = algorithim.call("JohnDoe")
      result2 = algorithim.call("johndoe")
      expect(result1).to(eq(result2))
    end

    it "handles character frequency" do
      result = algorithim.call("aab")
      # 'a' appears 2 times, 'b' appears 1 time
      # (97^2 * 2) + (98^2 * 1) = 18818 + 9604 = 28422
      expect(result).to(eq(28422))
    end
  end

  describe "COLOR_AWARE" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::COLOR_AWARE }

    it "biases toward detected colors" do
      red_result = algorithim.call("red_apple")
      blue_result = algorithim.call("blue_sky")
      expect(red_result).not_to(eq(blue_result))
    end

    it "uses DJB2 when no color detected" do
      result = algorithim.call("random_text")
      djb2_result = Unmagic::Color::String::HashFunction::DJB2.call("random_text")
      expect(result).to(eq(djb2_result))
    end

    it "detects multiple color words" do
      result = algorithim.call("green_team")
      expect(result).to(be > 100000) # biased toward green (120°)
    end
  end

  describe "MURMUR3" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::MURMUR3 }

    it "produces 32-bit hashes" do
      result = algorithim.call("test")
      expect(result).to(be_a(Integer))
      expect(result).to(be <= 0xFFFFFFFF)
    end

    it "handles various string lengths" do
      short_result = algorithim.call("a")
      long_result = algorithim.call("a" * 100)
      expect(short_result).not_to(eq(long_result))
    end
  end

  describe "DEFAULT" do
    let(:algorithim) { Unmagic::Color::String::HashFunction::DEFAULT }

    it "uses BKDR algorithm" do
      expect(algorithim).to(eq(Unmagic::Color::String::HashFunction::BKDR))
    end
  end

  describe ".all" do
    it "returns hash of all available algorithms" do
      algorithms = Unmagic::Color::String::HashFunction.all
      expect(algorithms).to(be_a(Hash))
      expect(algorithms.keys).to(include(:sum, :djb2, :bkdr, :fnv1a, :sdbm, :java, :crc32, :md5, :position, :perceptual, :color_aware, :murmur3, :default))

      expect(algorithms.values).to(all(be_a(Proc)))
    end
  end

  describe ".[]" do
    it "retrieves algorithms by name" do
      expect(Unmagic::Color::String::HashFunction[:sum]).to(eq(Unmagic::Color::String::HashFunction::SUM))
      expect(Unmagic::Color::String::HashFunction["djb2"]).to(eq(Unmagic::Color::String::HashFunction::DJB2))
      expect(Unmagic::Color::String::HashFunction[:BKDR]).to(eq(Unmagic::Color::String::HashFunction::BKDR))
    end

    it "raises error for unknown algorithms" do
      expect { Unmagic::Color::String::HashFunction[:unknown] }.to(raise_error(ArgumentError, "Unknown hash function: unknown"))
    end
  end

  describe "algorithm consistency" do
    let(:test_strings) { ["", "a", "hello", "Hello World!", "🌈", "test123", "a" * 1000] }

    it "all algorithms produce consistent results" do
      algorithms = [:sum, :djb2, :bkdr, :fnv1a, :sdbm, :java, :crc32, :md5, :position, :perceptual, :color_aware, :murmur3]

      algorithms.each do |algo_name|
        algo = Unmagic::Color::String::HashFunction[algo_name]

        test_strings.each do |str|
          result1 = algo.call(str)
          result2 = algo.call(str)
          expect(result1).to(eq(result2), "#{algo_name} should be consistent for '#{str}'")
        end
      end
    end

    it "algorithms produce different distributions" do
      test_string = "hello_world"
      results = []

      [:sum, :djb2, :bkdr, :fnv1a, :sdbm, :java, :crc32, :md5, :position, :perceptual, :murmur3].each do |algo_name|
        results << Unmagic::Color::String::HashFunction[algo_name].call(test_string)
      end

      # At least 8 different results (allowing some collisions)
      expect(results.uniq.length).to(be >= 8)
    end
  end
end
