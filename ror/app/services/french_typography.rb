# French typography and sanitization applied to user-entered text before save.
#
# Mirrors the original Nanoc `french_typography` filter plus input trimming:
#   - Thins whitespace around trimmed content
#   - `...` → `…`
#   - straight apostrophe `'` → curly `’`
#   - ` - ` → ` — ` (em dash)
#   - space before `; ! ?` → narrow no-break space (U+202F)
#   - space before `:` → no-break space (U+00A0)
class FrenchTypography
  NARROW_NO_BREAK_SPACE = "\u202F"
  NO_BREAK_SPACE = "\u00A0"
  ELLIPSIS = "\u2026"

  def self.sanitize(text)
    return text if text.nil?

    text
      .to_s
      .gsub(/[[:space:]]+/, " ")
      .strip
      .gsub("...", ELLIPSIS)
      .gsub("'", "’")
      .gsub(/([[:space:]]*)-([[:space:]])/, "\\1—\\2")
      .gsub(/[[:space:]]+([;!?])/, "#{NARROW_NO_BREAK_SPACE}\\1")
      .gsub(/[[:space:]]+([:])/, "#{NO_BREAK_SPACE}\\1")
  end
end
