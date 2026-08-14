# frozen_string_literal: true

require 'nokogiri'

class FrenchTypographyFilter < Nanoc::Filter
  identifier :french_typography

  NO_BREAK_SPACE = "\u00a0"
  ELLIPSIS = "\u2026"

  def run(content, params = {})
    content
      .gsub('...', ELLIPSIS)
      .gsub(/'/, '’')
      .gsub(/[ \t]+([;:!?])/, "#{NO_BREAK_SPACE}\\1")
  end
end
