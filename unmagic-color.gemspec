# frozen_string_literal: true

require_relative "lib/unmagic/color/version"

Gem::Specification.new do |spec|
  spec.name        = "unmagic-color"
  spec.version     = Unmagic::Color::VERSION
  spec.authors     = ["Keith Pitt"]
  spec.email       = ["keith@unreasonable-magic.com"]
  spec.summary     = "Comprehensive color manipulation library"
  spec.description = "Parse, convert, and manipulate colors with support for RGB, Hex, HSL formats, contrast calculations, and color blending"
  spec.homepage    = "https://github.com/unreasonable-magic/unmagic-color"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "data/**/*", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"
end
