# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "unmagic-color"
  spec.version     = "0.1.0"
  spec.authors     = ["Unmagic"]
  spec.email       = ["hello@unmagic.ai"]
  spec.summary     = "Comprehensive color manipulation library"
  spec.description = "Parse, convert, and manipulate colors with support for RGB, Hex, HSL formats, contrast calculations, and color blending"
  spec.homepage    = "https://unmagic.ai"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"
end
