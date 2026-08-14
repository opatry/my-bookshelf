# frozen_string_literal: true

require 'nokogiri'

class FrenchTypographyFilter < Nanoc::Filter
  identifier :french_typography

  NARROW_NO_BREAK_SPACE = "\u202F"
  NO_BREAK_SPACE = "\u00a0"
  ELLIPSIS = "\u2026"

  def run(content, params = {})
    content
      .gsub('...', ELLIPSIS)
      .gsub(/'/, '’')
      .gsub(/([\s]*)-([\s])/, "\\1—\\2")
      .gsub(/[ \t]+([;!?])/, "#{NARROW_NO_BREAK_SPACE}\\1")
      .gsub(/[ \t]+([:])/, "#{NO_BREAK_SPACE}\\1")
  end
end
