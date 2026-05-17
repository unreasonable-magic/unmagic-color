# frozen_string_literal: true

require "spec_helper"

# Proves that Unmagic::Color#scale can generate accurate Tailwind shades.
#
# Each example feeds a Tailwind v4 base color (the 500 stop) into #scale and
# measures how far every generated stop lands from Tailwind's published
# palette. The metric is ΔE: Euclidean distance in OKLab, where ~0.02 is
# roughly a just-noticeable difference and a generated palette within
# ~0.03-0.04 of a hand-tuned one is a close visual match.
#
# Tailwind v4 authors its palette in wide-gamut OKLCH, so comparison uses the
# unclamped scale (gamut: :none). The default :srgb path additionally clamps
# every stop for display — covered by its own example at the end.
RSpec.describe(Unmagic::Color::Harmony, "#scale") do
  # The 11 Tailwind stop labels, in scale order (lightest to darkest).
  def stops
    [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]
  end

  # Index of the 500 stop — the base color the scale is anchored on.
  def anchor_index
    5
  end

  # Tailwind v4's default palette as [lightness, chroma, hue] per stop.
  # Source: tailwindcss theme.css, lightness converted from percent to ratio.
  def tailwind_v4
    {
      "red" => [
        [0.971, 0.013, 17.38],
        [0.936, 0.032, 17.717],
        [0.885, 0.062, 18.334],
        [0.808, 0.114, 19.571],
        [0.704, 0.191, 22.216],
        [0.637, 0.237, 25.331],
        [0.577, 0.245, 27.325],
        [0.505, 0.213, 27.518],
        [0.444, 0.177, 26.899],
        [0.396, 0.141, 25.723],
        [0.258, 0.092, 26.042],
      ],
      "blue" => [
        [0.970, 0.014, 254.604],
        [0.932, 0.032, 255.585],
        [0.882, 0.059, 254.128],
        [0.809, 0.105, 251.813],
        [0.707, 0.165, 254.624],
        [0.623, 0.214, 259.815],
        [0.546, 0.245, 262.881],
        [0.488, 0.243, 264.376],
        [0.424, 0.199, 265.638],
        [0.379, 0.146, 265.522],
        [0.282, 0.091, 267.935],
      ],
      "amber" => [
        [0.987, 0.022, 95.277],
        [0.962, 0.059, 95.617],
        [0.924, 0.120, 95.746],
        [0.879, 0.169, 91.605],
        [0.828, 0.189, 84.429],
        [0.769, 0.188, 70.080],
        [0.666, 0.179, 58.318],
        [0.555, 0.163, 48.998],
        [0.473, 0.137, 46.201],
        [0.414, 0.112, 45.904],
        [0.279, 0.077, 45.635],
      ],
      "slate" => [
        [0.984, 0.003, 247.858],
        [0.968, 0.007, 247.896],
        [0.929, 0.013, 255.508],
        [0.869, 0.022, 252.894],
        [0.704, 0.040, 256.788],
        [0.554, 0.046, 257.417],
        [0.446, 0.043, 257.281],
        [0.372, 0.044, 257.287],
        [0.279, 0.041, 260.031],
        [0.208, 0.042, 265.755],
        [0.129, 0.042, 264.695],
      ],
    }
  end

  def oklch(lightness, chroma, hue)
    Unmagic::Color::OKLCH.new(lightness: lightness, chroma: chroma, hue: hue)
  end

  def reference(family)
    tailwind_v4.fetch(family).map { |l, c, h| oklch(l, c, h) }
  end

  # ΔE — Euclidean distance between two colors in OKLab.
  def delta_e(color_a, color_b)
    la, aa, ba = color_a.to_oklab
    lb, ab, bb = color_b.to_oklab
    Math.sqrt(((la - lb)**2) + ((aa - ab)**2) + ((ba - bb)**2))
  end

  def mean(values)
    values.sum / values.length
  end

  # Generate an 11-step scale anchored on Tailwind's 500 stop, line it up
  # against the published palette, print the comparison, and return the
  # per-stop ΔE values.
  def deltas_for(family, **options)
    ref = reference(family)
    generated = ref[anchor_index].scale(steps: 11, anchor: anchor_index, gamut: :none, **options)
    deltas = generated.each_index.map { |i| delta_e(generated[i], ref[i]) }
    print_report(family, generated, ref, deltas)
    deltas
  end

  def print_report(family, generated, reference, deltas)
    puts "\n#{family} — #scale vs Tailwind v4 (ΔE in OKLab)"
    stops.each_with_index do |stop, i|
      g = generated[i]
      r = reference[i]
      puts format(
        "  %4d  generated L%.3f C%.3f H%6.1f   tailwind L%.3f C%.3f H%6.1f   ΔE %.4f",
        stop,
        g.lightness,
        g.chroma.value,
        g.hue.value,
        r.lightness,
        r.chroma.value,
        r.hue.value,
        deltas[i],
      )
    end
    puts format("        mean ΔE %.4f   max ΔE %.4f", mean(deltas), deltas.max)
  end

  describe "reproduces chromatic ramps from the base color alone" do
    # No tuning whatsoever: the 500 color in, scale(steps: 11, anchor: 5) out.
    # The default lightness and chroma curves do the rest.
    ["red", "blue"].each do |family|
      it "matches Tailwind #{family} within ΔE 0.035 across all 11 stops" do
        deltas = deltas_for(family)

        expect(deltas[anchor_index]).to(be < 1e-6) # the anchored 500 stop is exact
        expect(deltas.max).to(be <= 0.035)
        expect(mean(deltas)).to(be <= 0.020)
      end
    end
  end

  describe "reproduces a near-neutral ramp given its lightness curve" do
    # Gray ramps run far darker and flatter than chromatic ones, so the
    # default lightness curve does not fit them. Supplying the lightness
    # values is enough — chroma and hue are still derived by #scale.
    it "matches Tailwind slate within ΔE 0.03 across all 11 stops" do
      lightness = tailwind_v4.fetch("slate").map { |l, _c, _h| l }
      deltas = deltas_for("slate", lightness: lightness)

      expect(deltas.max).to(be <= 0.03)
      expect(mean(deltas)).to(be <= 0.012)
    end
  end

  describe "approximates a warm ramp, with a documented residual" do
    # Amber's hue swings ~50° from stop 50 to 950; that drift is supplied
    # here as hue_shift. The residual — worst around stops 200-300 — is
    # amber's chroma curve, which peaks earlier and higher than chromatic
    # hues. That shape cannot be inferred from a single base color; matching
    # it exactly needs an explicit `chroma:` curve.
    it "matches Tailwind amber within ΔE 0.085 with a hue-drift hint" do
      deltas = deltas_for("amber", hue_shift: 25.2..-24.4)

      expect(deltas.max).to(be <= 0.085)
      expect(mean(deltas)).to(be <= 0.05)
    end
  end

  describe "the default path keeps every stop displayable" do
    # The accuracy examples above use gamut: :none to compare against
    # Tailwind's wide-gamut OKLCH. The default gamut: :srgb instead pulls
    # every stop into the sRGB gamut so RGB#to_hex is trustworthy.
    ["red", "blue", "amber", "slate"].each do |family|
      it "gamut-maps every #{family} stop into sRGB" do
        scale = reference(family)[anchor_index].scale(steps: 11, anchor: anchor_index)

        expect(scale.map(&:in_gamut?)).to(all(be(true)))
      end
    end
  end
end
