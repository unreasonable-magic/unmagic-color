# frozen_string_literal: true

module Unmagic
  class Color
    class RGB < Color
      # Named colors support for RGB colors with X11 and CSS/W3C databases.
      #
      # Provides access to named colors from two databases:
      # - X11 database (658 colors) - default
      # - CSS/W3C database (148 colors) - accessible via prefix
      #
      # @example Parse a named color (uses X11 by default)
      #   Unmagic::Color::RGB::Named.parse("goldenrod")
      #   #=> RGB instance for #daa520
      #
      # @example Use CSS/W3C database with prefix
      #   Unmagic::Color::RGB::Named.parse("css:gray")
      #   #=> RGB instance for #808080 (CSS value)
      #   Unmagic::Color::RGB::Named.parse("gray")
      #   #=> RGB instance for #bebebe (X11 value)
      #
      # @example Case-insensitive and whitespace-tolerant
      #   Unmagic::Color::RGB::Named.parse("Golden Rod")
      #   #=> RGB instance for #daa520
      #   Unmagic::Color::RGB::Named.parse("GOLDENROD")
      #   #=> RGB instance for #daa520
      #
      # Five colors have different values between databases:
      # gray/grey (#bebebe X11 vs #808080 CSS), green (#00ff00 X11 vs #008000 CSS),
      # maroon (#b03060 X11 vs #800000 CSS), purple (#a020f0 X11 vs #800080 CSS)
      #
      # @example Check if a name is valid
      #   Unmagic::Color::RGB::Named.valid?("goldenrod")
      #   #=> true
      #   Unmagic::Color::RGB::Named.valid?("notacolor")
      #   #=> false
      class Named
        # Database for loading and accessing color data from files.
        #
        # Handles lazy loading, name normalization, and color lookup.
        # @api private
        class Database
          # @api private
          attr_reader :name, :aliases

          # Initialize a new color database.
          #
          # @param filepath [String] Path to the database file
          # @param name [String, nil] The name of the database (e.g., "x11", "css")
          # @param aliases [Array<String>] Alternative names for the database
          def initialize(filepath, name: nil, aliases: [])
            @filepath = filepath
            @name = name
            @aliases = aliases
            @data = nil
          end

          # Lookup color by name, returns RGB color or nil.
          #
          # @param color_name [String] The color name to lookup
          # @return [RGB, nil] The RGB color instance or nil if not found
          def [](color_name)
            normalized = normalize_name(color_name)
            hex_value = data[normalized]
            hex_value ? Hex.parse(hex_value) : nil
          end

          # Check if color exists in database.
          #
          # @param color_name [String] The color name to check
          # @return [Boolean] true if color exists
          def valid?(color_name)
            normalized = normalize_name(color_name)
            data.key?(normalized)
          end

          # Get all color names in database.
          #
          # @return [Array<String>] Array of all color names
          def all
            data.keys
          end

          # Check if database has been loaded.
          #
          # @return [Boolean] true if data has been loaded from file
          def loaded?
            !@data.nil?
          end

          # Calculate memory size of loaded database.
          #
          # @return [Integer] Memory size in bytes
          # @api private
          def memsize
            require "objspace"

            memory = ObjectSpace.memsize_of(data)

            data.each do |key, value|
              memory += ObjectSpace.memsize_of(key)
              memory += ObjectSpace.memsize_of(value)
            end

            memory
          end

          private

          # Lazy load data from file.
          #
          # @return [Hash] Hash of normalized color names to hex values
          def data
            @data ||= load_data
          end

          # Normalize color name for lookup.
          # Converts to lowercase and removes all whitespace.
          #
          # @param name [String] The color name to normalize
          # @return [String] The normalized name
          def normalize_name(name)
            name.to_s.downcase.gsub(/\s+/, "")
          end

          # Load and parse database file.
          #
          # @return [Hash] Hash of normalized color names to hex values
          def load_data
            unless File.exist?(@filepath)
              raise Error, "Color database file not found: #{@filepath}"
            end

            colors = {}

            File.readlines(@filepath).each do |line|
              name, hex = line.strip.split("\t")
              next if name.nil? || hex.nil?

              # Normalize hex value (fix double ## issue)
              hex = hex.sub(/^#+/, "#").freeze

              # Skip duplicates (keep first occurrence)
              normalized = normalize_name(name)
              next if colors.key?(normalized)

              colors[normalized] = hex
            end

            colors
          end
        end

        # Error raised when a color name is not found
        class ParseError < Color::Error; end

        # X11 color database (658 colors)
        X11 = Database.new(File.join(Color::DATA_PATH, "x11.txt"), name: "x11")

        # CSS/W3C color database (148 colors)
        CSS = Database.new(File.join(Color::DATA_PATH, "css.txt"), name: "css", aliases: ["w3c"])

        class << self
          # Parse a named color and return its RGB representation.
          #
          # Supports database prefixes (css:, w3c:, x11:) to select specific database.
          # Without prefix, uses X11 database by default.
          #
          # @param name [String] The color name to parse (case-insensitive)
          # @return [RGB] The RGB color instance
          # @raise [ParseError] If the color name is not recognized
          #
          # @example Parse from X11 database (default)
          #   Unmagic::Color::RGB::Named.parse("goldenrod")
          #   #=> RGB instance for #daa520
          #
          # @example Parse from CSS database
          #   Unmagic::Color::RGB::Named.parse("css:gray")
          #   #=> RGB instance for #808080
          def parse(name)
            database, color_name = resolve_database(name)
            color = database[color_name]

            raise ParseError, "Unknown color name in #{database.name} database: #{color_name.inspect}" unless color

            color
          end

          # Check if a color name is valid.
          #
          # Supports database prefixes to check specific database.
          #
          # @param name [String] The color name to check
          # @return [Boolean] true if the name exists
          #
          # @example Check in X11 database (default)
          #   Unmagic::Color::RGB::Named.valid?("goldenrod")
          #   #=> true
          #
          # @example Check in CSS database
          #   Unmagic::Color::RGB::Named.valid?("css:gray")
          #   #=> true
          def valid?(name)
            database, color_name = resolve_database(name)
            database.valid?(color_name)
          end

          # Get all available color databases.
          #
          # @return [Array<Database>] Array of database instances
          #
          # @example Get all databases
          #   Unmagic::Color::RGB::Named.databases
          #   #=> [X11, CSS]
          #
          # @example Get color names from a specific database
          #   Unmagic::Color::RGB::Named.databases.first.all.take(5)
          #   #=> ["aliceblue", "antiquewhite", ...]
          def databases
            [X11, CSS]
          end

          # Find a database by name or alias.
          #
          # @param search [String] Name or alias to search for
          # @return [Database, nil] Matching database or nil
          #
          # @example Find by name
          #   Unmagic::Color::RGB::Named.find_by_name("x11")
          #   #=> X11 database
          #
          # @example Find by alias
          #   Unmagic::Color::RGB::Named.find_by_name("w3c")
          #   #=> CSS database
          def find_by_name(search)
            normalized = search.strip.downcase
            all_by_name.fetch(normalized)
          rescue KeyError
            nil
          end

          private

          # Hash mapping all database names and aliases to their instances.
          #
          # @return [Hash<String, Database>] Name/alias to database mapping
          def all_by_name
            @all_by_name ||= begin
              hash = {}
              databases.each do |database|
                hash[database.name] = database
                database.aliases.each { |alias_name| hash[alias_name] = database }
              end
              hash
            end
          end

          # Resolve database and color name from input.
          #
          # Extracts database prefix if present (css:, w3c:, x11:).
          # Returns the appropriate database instance and cleaned color name.
          #
          # @param name [String] The input name (may include prefix)
          # @return [Array<Database, String>] Database instance and color name
          def resolve_database(name)
            if name.include?(":")
              prefix, color_name = name.split(":", 2)
              database = find_by_name(prefix)

              # Invalid prefix, treat whole string as color name
              return [X11, name] unless database

              [database, color_name]
            else
              [X11, name]
            end
          end
        end
      end
    end
  end
end
