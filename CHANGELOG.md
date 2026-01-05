# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] - 2026-01-05

### Added
- `Gradient::Bitmap#to_ansi` method to render gradients as colored blocks in terminal

## [0.2.1] - 2026-01-05

### Added
- `to_hex` method for HSL colors (converts via RGB)
- `to_hex` method for OKLCH colors (converts via RGB)

## [0.2.0] - 2026-01-05

### Added

#### Color Harmonies
- `complementary` - returns the opposite color on the color wheel (180° shift)
- `analogous(angle: 30)` - returns two adjacent colors at ±angle degrees
- `triadic` - returns two colors equally spaced at +120° and +240°
- `split_complementary(angle: 30)` - returns two colors flanking the complement
- `tetradic_square` - returns three colors at +90°, +180°, +270°
- `tetradic_rectangle(angle: 60)` - returns three colors forming a rectangle on the wheel

#### Color Variations
- `monochromatic(steps: 5)` - generates colors with varying lightness
- `shades(steps: 5, amount: 0.5)` - generates progressively darker colors
- `tints(steps: 5, amount: 0.5)` - generates progressively lighter colors
- `tones(steps: 5, amount: 0.5)` - generates progressively desaturated colors

#### Gradients
- `Unmagic::Color::Gradient.linear` - create gradients with automatic color space detection
- `Unmagic::Color::RGB::Gradient::Linear` - RGB color space gradients
- `Unmagic::Color::HSL::Gradient::Linear` - HSL color space gradients (smoother hue transitions)
- `Unmagic::Color::OKLCH::Gradient::Linear` - OKLCH gradients (perceptually uniform)
- Support for gradient directions: keywords (`to right`), angles (`45deg`), and from/to syntax
- 2D gradient rasterization with `width` and `height` parameters
- Explicit color stop positions (like CSS `linear-gradient`)

#### Alpha Channel
- Alpha channel support for RGB, HSL, and OKLCH colors
- Parse alpha from CSS color functions: `rgba()`, `hsla()`, `oklch()` with alpha
- `Alpha` class with CSS ratio output (`to_css` returns 0.0-1.0)

#### ANSI Terminal Colors
- ANSI escape code parsing (3/4-bit, 256-color, and 24-bit true color)
- `to_ansi` method with `mode:` parameter (`:truecolor`, `:palette256`, `:palette16`)
- Truecolor (24-bit) output by default for accurate color reproduction
- Support for both foreground and background layers
- Color swatches in `pretty_print` output

#### Console Tools
- `Unmagic::Color::Console::Card` - render color profile cards with harmonies and variations
- `Unmagic::Color::Console::Banner` - gradient ASCII art banner
- `Unmagic::Color::Console::Help` - syntax-highlighted help text
- `Unmagic::Color::Console::Highlighter` - Ruby syntax highlighting with customizable colors

#### Other
- Full X11 color database (658 colors) with lazy loading
- JSON storage for color databases (faster loading, ~54KB for X11)
- `build` class method with positional arguments: `RGB.build(255, 87, 51)`
- Improved percentage parsing with fraction notation support (`1/2` = 50%)

### Changed
- Default ANSI output mode changed from `:palette16` to `:truecolor` for better color accuracy
- Color databases are now stored as JSON for faster parsing

## [0.1.0] - 2026-01-01

### Added
- Initial release
- RGB, HSL, and OKLCH color space support
- Color parsing from hex, CSS functions, and X11 named colors
- Color manipulation (lighten, darken, blend)
- Color space conversions
- Deterministic color generation from strings
- Luminance calculations and light/dark detection
- HSL color progressions for palette generation
- Multiple hash functions for string-to-color derivation

[0.2.2]: https://github.com/unreasonable-magic/unmagic-color/releases/tag/v0.2.2
[0.2.1]: https://github.com/unreasonable-magic/unmagic-color/releases/tag/v0.2.1
[0.2.0]: https://github.com/unreasonable-magic/unmagic-color/releases/tag/v0.2.0
[0.1.0]: https://github.com/unreasonable-magic/unmagic-color/releases/tag/v0.1.0
