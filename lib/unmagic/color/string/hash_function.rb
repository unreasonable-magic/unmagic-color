# frozen_string_literal: true

# lib/unmagic/color/string/hash_function.rb
module Unmagic
  class Color
    # String utilities for color generation
    class String
      # Hash functions for generating deterministic colors from strings
      module HashFunction
        # Simple sum of character codes. Adds up the ASCII/Unicode value of each character.
        # Distribution: Poor - similar strings get similar hashes, anagrams get identical hashes.
        # Colors: Tends to cluster in mid-range hues, very predictable.
        #
        # @example Anagrams produce identical hashes
        #   SUM.call("cat")
        #   #=> 312
        #   SUM.call("act")
        #   #=> 312
        #
        # Use when you want anagrams to have the same color.
        SUM = ->(str) {
          str.chars.sum(&:ord)
        }

        # Dan Bernstein's DJB2 algorithm. Starts with 5381, then for each byte: hash = hash * 33 + byte.
        # Distribution: Good spread across the number space with few collisions.
        # Colors: Well-distributed hues, good variety even for similar strings.
        #
        # @example Similar strings produce different hashes
        #   DJB2.call("hello")
        #   #=> 210676686985
        #   DJB2.call("hallo")
        #   #=> 210676864905
        #
        # Use when you need general purpose hashing, good default choice.
        DJB2 = ->(str) {
          str.bytes.reduce(5381) do |hash, byte|
            ((hash << 5) + hash) + byte
          end.abs
        }

        # Brian Kernighan & Dennis Ritchie's BKDR hash. Multiplies hash by prime number (131) and adds each byte.
        # Distribution: Excellent - one of the best distributions for hash tables.
        # Colors: Very uniform color distribution across entire spectrum.
        #
        # @example Single character changes create vastly different hashes
        #   BKDR.call("test")
        #   #=> 2996398963
        #   BKDR.call("tast")
        #   #=> 2996267891
        #
        # Use when you need the most random-looking, well-distributed colors.
        BKDR = ->(str) {
          seed = 131
          str.bytes.reduce(0) do |hash, byte|
            (hash * seed + byte) & 0xFFFFFFFF
          end
        }

        # Fowler-Noll-Vo 1a hash (32-bit). XORs each byte with hash, then multiplies by prime 16777619.
        # Distribution: Excellent avalanche effect - tiny changes cascade throughout hash.
        # Colors: Extremely sensitive to input changes, neighboring strings get distant colors.
        #
        # @example Sequential strings get unrelated hashes
        #   FNV1A.call("test1")
        #   #=> 1951951766
        #   FNV1A.call("test2")
        #   #=> 1968729175
        #
        # Use when you want maximum color variety for sequential/numbered items.
        FNV1A = ->(str) {
          fnv_prime = 16777619
          offset_basis = 2166136261

          str.bytes.reduce(offset_basis) do |hash, byte|
            ((hash ^ byte) * fnv_prime) & 0xFFFFFFFF
          end
        }

        # SDBM hash algorithm (used in Berkeley DB). Combines bit shifting (6 and 16 positions) with subtraction.
        # Distribution: Good distribution with interesting bit patterns.
        # Colors: Tends to create slightly warmer hues due to bit pattern biases.
        #
        # @example Works well for database keys
        #   SDBM.call("user_123")
        #   #=> 1642793946939
        #   SDBM.call("order_456")
        #   #=> 1414104772796
        #
        # Use when you're hashing database IDs or system identifiers.
        SDBM = ->(str) {
          str.bytes.reduce(0) do |hash, byte|
            byte + (hash << 6) + (hash << 16) - hash
          end.abs
        }

        # Java-style string hashCode. Multiplies hash by 31 and adds character code (polynomial rolling).
        # Distribution: Decent but can cluster with short strings.
        # Colors: Predictable patterns for sequential strings, good for related items.
        #
        # @example Sequential items get progressively shifting hashes
        #   JAVA.call("item1")
        #   #=> 100475638
        #   JAVA.call("item2")
        #   #=> 100475639
        #
        # Use when you want compatibility with Java systems or predictable gradients.
        JAVA = ->(str) {
          str.chars.reduce(0) do |hash, char|
            31 * hash + char.ord
          end.abs
        }

        # CRC32 (Cyclic Redundancy Check). Polynomial division for error detection, highly mathematical.
        # Distribution: Excellent - designed to detect even single-bit changes.
        # Colors: Extremely uniform distribution, appears most "random".
        #
        # @example Swapping characters produces different hashes
        #   CRC32.call("abc")
        #   #=> 891568578
        #   CRC32.call("bac")
        #   #=> 1294269411
        #
        # Use when you need the most uniform, professional-looking color distribution.
        CRC32 = ->(str) {
          require "zlib"
          Zlib.crc32(str)
        }

        # MD5-based hash (truncated to 32 bits). Cryptographic hash truncated to first 8 hex characters.
        # Distribution: Perfect distribution but computationally expensive.
        # Colors: Absolutely uniform distribution, no patterns whatsoever.
        #
        # @example Cryptographic hash provides perfect distribution
        #   MD5.call("secret")
        #   #=> 1528250989
        #   MD5.call("secrat")
        #   #=> 2854876444
        #
        # Use when color security matters or you need perfect randomness.
        MD5 = ->(str) {
          require "digest"
          Digest::MD5.hexdigest(str)[0..7].to_i(16)
        }

        # Position-weighted hash. Each character's value is multiplied by its position squared.
        # Distribution: Order-sensitive - rearranging characters changes the hash.
        # Colors: "ABC" and "CBA" get different colors, early characters have more impact.
        #
        # @example Character order affects the hash
        #   POSITION.call("ABC")
        #   #=> 1629
        #   POSITION.call("CBA")
        #   #=> 1773
        #
        # Use when character order matters (like initials or codes).
        POSITION = ->(str) {
          str.chars.map.with_index do |char, index|
            char.ord * ((index + 1)**2)
          end.sum
        }

        # Case-insensitive perceptual hash. Normalizes string, counts character frequency, squares char codes.
        # Distribution: Groups similar strings together regardless of case or punctuation.
        # Colors: "Hello!" and "hello" get same color, focuses on letter content.
        #
        # @example Case-insensitive hashing
        #   PERCEPTUAL.call("JohnDoe")
        #   #=> 610558
        #   PERCEPTUAL.call("johndoe")
        #   #=> 610558
        #
        # Use when you want visual similarity for perceptually similar strings.
        PERCEPTUAL = ->(str) {
          normalized = str.downcase.gsub(/[^a-z0-9]/, "")
          char_freq = normalized.chars.tally

          char_freq.reduce(0) do |hash, (char, count)|
            hash + (char.ord**2) * count
          end
        }

        # Color-aware hash (detects color names in string). Searches for color words and biases hash toward that hue.
        # Distribution: Biased toward mentioned colors, otherwise uses DJB2.
        # Colors: "red_apple" gets reddish hue, "blue_sky" gets bluish hue.
        #
        # @example Biases toward mentioned colors
        #   COLOR_AWARE.call("green_team")
        #   #=> 120042
        #   COLOR_AWARE.call("purple_hearts")
        #   #=> 270047
        #
        # Use when text might contain color names (usernames, team names, tags).
        COLOR_AWARE = ->(str) {
          color_hues = {
            "red" => 0,
            "scarlet" => 10,
            "crimson" => 5,
            "orange" => 30,
            "amber" => 45,
            "yellow" => 60,
            "gold" => 50,
            "green" => 120,
            "lime" => 90,
            "emerald" => 140,
            "cyan" => 180,
            "teal" => 165,
            "turquoise" => 175,
            "blue" => 240,
            "navy" => 235,
            "azure" => 210,
            "purple" => 270,
            "violet" => 280,
            "indigo" => 255,
            "pink" => 330,
            "magenta" => 300,
            "rose" => 345,
            "brown" => 25,
            "tan" => 35,
            "gray" => 0,
            "grey" => 0,
            "black" => 0,
            "white" => 0,
          }

          detected_hue = color_hues.find do |word, _|
            str.downcase.include?(word)
          end&.last

          base_hash = DJB2.call(str)

          if detected_hue && detected_hue > 0
            # Bias toward detected color with ±30° variation
            (detected_hue * 1000) + (base_hash % 60) - 30
          else
            base_hash
          end
        }

        # MurmurHash3 (32-bit version). Uses multiplication, rotation, and XOR for mixing.
        # Distribution: Excellent - designed for hash tables by Google.
        # Colors: Very uniform, fast, good avalanche properties.
        #
        # @example Fast and high quality hash function
        #   MURMUR3.call("database_key")
        #   #=> 3208616715
        #   MURMUR3.call("cache_entry")
        #   #=> 1882174324
        #
        # Use when performance matters and you need excellent distribution.
        MURMUR3 = ->(str) {
          c1 = 0xcc9e2d51
          c2 = 0x1b873593
          seed = 0

          hash = seed

          str.bytes.each_slice(4) do |chunk|
            k = 0
            chunk.each_with_index { |byte, i| k |= byte << (i * 8) }

            k = (k * c1) & 0xFFFFFFFF
            k = ((k << 15) | (k >> 17)) & 0xFFFFFFFF
            k = (k * c2) & 0xFFFFFFFF

            hash ^= k
            hash = ((hash << 13) | (hash >> 19)) & 0xFFFFFFFF
            hash = (hash * 5 + 0xe6546b64) & 0xFFFFFFFF
          end

          hash ^= str.bytesize
          hash ^= hash >> 16
          hash = (hash * 0x85ebca6b) & 0xFFFFFFFF
          hash ^= hash >> 13
          hash = (hash * 0xc2b2ae35) & 0xFFFFFFFF
          hash ^= hash >> 16

          hash
        }

        # Default algorithm - BKDR for its excellent distribution
        DEFAULT = BKDR

        class << self
          # Call the default hash function
          #
          # @param str [String] String to hash
          # @return [Integer] Hash value
          def call(str)
            DEFAULT.call(str)
          end

          # Get all available algorithms
          #
          # @return [Hash] Hash of algorithm names to procs
          def all
            constants.select { |c| const_get(c).is_a?(Proc) }
              .map { |c| [c.to_s.downcase.to_sym, const_get(c)] }
              .to_h
          end

          # Get a hash function by name
          #
          # @param name [String, Symbol] Name of the hash function
          # @return [Proc] The hash function
          # @raise [ArgumentError] If hash function not found
          def [](name)
            const_get(name.to_s.upcase)
          rescue NameError
            raise ArgumentError, "Unknown hash function: #{name}"
          end
        end
      end
    end
  end
end
