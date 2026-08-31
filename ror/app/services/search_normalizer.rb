# Normalizes French text for accent- and quote-insensitive search matching.
#
# Portable: all transformation happens in Ruby (no database-specific functions),
# so it works on any database engine. Mirrors the original Fuse.js
# `ignoreDiacritics` behavior. Used symmetrically on both stored search vectors
# and user queries so that e.g. "étranger" and "etranger", or "L'Étranger" and
# "L’Étranger", match each other.
class SearchNormalizer
  def self.normalize(text)
    text.to_s
        .unicode_normalize(:nfkd)
        .gsub(/[\u0300-\u036f]/, "")
        .downcase
        .gsub(/[^0-9a-z]+/, " ")
        .strip
  end
end
