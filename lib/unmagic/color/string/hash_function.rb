# frozen_string_literal: true

# lib/unmagic/color/string/hash_function.rb
module Unmagic
  class Color
    class String
      module HashFunction
        # Simple sum of character codes
        # How it works: Adds up the ASCII/Unicode value of each character
        # Distribution: Poor - similar strings get similar hashes, anagrams get identical hashes
        # Colors: Tends to cluster in mid-range hues, very predictable
        # Example: "cat" (99+97+116=312) and "act" (97+99+116=312) produce identical colors
        # Use when: You want anagrams to have the same color
        SUM = ->(str) {
          str.chars.sum(&:ord)
        }

        # Dan Bernstein's DJB2 algorithm
        # How it works: Starts with 5381, then for each byte: hash = hash * 33 + byte
        # Distribution: Good spread across the number space with few collisions
        # Colors: Well-distributed hues, good variety even for similar strings
        # Example: "hello" and "hallo" produce completely different colors
        # Use when: General purpose, good default choice
        DJB2 = ->(str) {
          str.bytes.reduce(5381) do |hash, byte|
            ((hash << 5) + hash) + byte
          end.abs
        }

        # Brian Kernighan & Dennis Ritchie's BKDR hash
        # How it works: Multiplies hash by prime number (131) and adds each byte
        # Distribution: Excellent - one of the best distributions for hash tables
        # Colors: Very uniform color distribution across entire spectrum
        # Example: Even single character changes create vastly different hues
        # Use when: You need the most random-looking, well-distributed colors
        BKDR = ->(str) {
          seed = 131
          str.bytes.reduce(0) do |hash, byte|
            (hash * seed + byte) & 0xFFFFFFFF
          end
        }

        # Fowler-Noll-Vo 1a hash (32-bit)
        # How it works: XORs each byte with hash, then multiplies by prime 16777619
        # Distribution: Excellent avalanche effect - tiny changes cascade throughout hash
        # Colors: Extremely sensitive to input changes, neighboring strings get distant colors
        # Example: "test1", "test2", "test3" all get completely unrelated colors
        # Use when: You want maximum color variety for sequential/numbered items
        FNV1A = ->(str) {
          fnv_prime = 16777619
          offset_basis = 2166136261

          str.bytes.reduce(offset_basis) do |hash, byte|
            ((hash ^ byte) * fnv_prime) & 0xFFFFFFFF
          end
        }

        # SDBM hash algorithm (used in Berkeley DB)
        # How it works: Combines bit shifting (6 and 16 positions) with subtraction
        # Distribution: Good distribution with interesting bit patterns
        # Colors: Tends to create slightly warmer hues due to bit pattern biases
        # Example: Works well for database keys and identifiers
        # Use when: You're hashing database IDs or system identifiers
        SDBM = ->(str) {
          str.bytes.reduce(0) do |hash, byte|
            byte + (hash << 6) + (hash << 16) - hash
          end.abs
        }

        # Java-style string hashCode
        # How it works: Multiplies hash by 31 and adds character code (polynomial rolling)
        # Distribution: Decent but can cluster with short strings
        # Colors: Predictable patterns for sequential strings, good for related items
        # Example: "item1", "item2", "item3" get progressively shifting hues
        # Use when: You want compatibility with Java systems or predictable gradients
        JAVA = ->(str) {
          str.chars.reduce(0) do |hash, char|
            31 * hash + char.ord
          end.abs
        }

        # CRC32 (Cyclic Redundancy Check)
        # How it works: Polynomial division for error detection, highly mathematical
        # Distribution: Excellent - designed to detect even single-bit changes
        # Colors: Extremely uniform distribution, appears most "random"
        # Example: Even swapping two characters produces completely different colors
        # Use when: You need the most uniform, professional-looking color distribution
        CRC32 = ->(str) {
          require "zlib"
          Zlib.crc32(str)
        }

        # MD5-based hash (truncated to 32 bits)
        # How it works: Cryptographic hash truncated to first 8 hex characters
        # Distribution: Perfect distribution but computationally expensive
        # Colors: Absolutely uniform distribution, no patterns whatsoever
        # Example: Impossible to predict color without calculating
        # Use when: Color security matters (???) or you need perfect randomness
        MD5 = ->(str) {
          require "digest"
          Digest::MD5.hexdigest(str)[0..7].to_i(16)
        }

        # Position-weighted hash
        # How it works: Each character's value is multiplied by its position squared
        # Distribution: Order-sensitive - rearranging characters changes the hash
        # Colors: "ABC" and "CBA" get different colors, early characters have more impact
        # Example: First letter has huge influence on hue, last letters fine-tune it
        # Use when: Character order matters (like initials or codes)
        POSITION = ->(str) {
          str.chars.map.with_index do |char, index|
            char.ord * ((index + 1)**2)
          end.sum
        }

        # Case-insensitive perceptual hash
        # How it works: Normalizes string, counts character frequency, squares char codes
        # Distribution: Groups similar strings together regardless of case or punctuation
        # Colors: "Hello!" and "hello" get same color, focuses on letter content
        # Example: Good for usernames where "JohnDoe" and "johndoe" should match
        # Use when: You want visual similarity for perceptually similar strings
        PERCEPTUAL = ->(str) {
          normalized = str.downcase.gsub(/[^a-z0-9]/, "")
          char_freq = normalized.chars.tally

          char_freq.reduce(0) do |hash, (char, count)|
            hash + (char.ord**2) * count
          end
        }

        # Color-aware hash (detects color names in string)
        # How it works: Searches for color words and biases hash toward that hue
        # Distribution: Biased toward mentioned colors, otherwise uses DJB2
        # Colors: "red_apple" gets reddish hue, "blue_sky" gets bluish hue
        # Example: "green_team" → greenish, "purple_hearts" → purplish
        # Use when: Text might contain color names (usernames, team names, tags)
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

        # MurmurHash3 (32-bit version)
        # How it works: Uses multiplication, rotation, and XOR for mixing
        # Distribution: Excellent - designed for hash tables by Google
        # Colors: Very uniform, fast, good avalanche properties
        # Example: Widely used in distributed systems for its speed and quality
        # Use when: Performance matters and you need excellent distribution
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
          def call(str)
            DEFAULT.call(str)
          end

          # Get all available algorithms
          def all
            constants.select { |c| const_get(c).is_a?(Proc) }
              .map { |c| [c.to_s.downcase.to_sym, const_get(c)] }
              .to_h
          end

          # Get a hash function by name
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
