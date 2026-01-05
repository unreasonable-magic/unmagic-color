# frozen_string_literal: true

# Adds inline color swatches for hex colors inside <code>…</code> blocks.

require "yard"
require "redcarpet"

module YardSwatches
  HEX_RE = /#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b/.freeze

  class Renderer < Redcarpet::Render::HTML
    # Use postprocess to add swatches outside of code blocks
    def postprocess(html)
      # Find <code> blocks that contain only a hex color
      html.gsub(%r{<code>(#{HEX_RE})</code>}) do
        hex = Regexp.last_match(1)
        swatch = %(<span aria-hidden="true" style="display:inline-block;width:.9em;height:.9em;margin-right:.35em;vertical-align:-0.1em;border:1px solid rgba(0,0,0,.25);border-radius:3px;background:#{hex};"></span>)
        "#{swatch}<code>#{hex}</code>"
      end
    end
  end

  # This is the class YARD loads as the "markdown document" implementation.
  class RedcarpetDocument
    def initialize(text)
      @text = text
    end

    def to_html
      renderer = Renderer.new
      markdown = Redcarpet::Markdown.new(
        renderer,
        fenced_code_blocks: true,
        tables: true,
        strikethrough: true,
        lax_spacing: true,
      )
      markdown.render(@text)
    end
  end
end

# Tell YARD: when using the :markdown markup type with the :redcarpet provider,
# use our document class instead of the default.
YARD::Templates::Helpers::MarkupHelper::MARKUP_PROVIDERS[:markdown].each do |provider|
  next unless provider[:lib] == :redcarpet

  provider[:const] = "YardSwatches::RedcarpetDocument"
end
