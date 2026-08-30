# Value object for ISBN-13 numbers.
#
# Handles the ISBN-13 definition checksum and a human-friendly display format
# (e.g. 978-2-1005-1234-5 inferred from the ISBN structure). The product code
# boundaries are not standardized worldwide, so we only group the first three
# digits (GS1 prefix) and keep the rest when formatting.
#
# NOTE: the constant is named `Isbn13` (not `ISBN13`) so it matches Zeitwerk's
# inflector (`app/models/isbn13.rb` → `Isbn13`).
class Isbn13
  WEIGHTS = [ 1, 3 ].freeze

  # Returns the 13-digit string or nil if `value` is not a clean 13-digit number.
  def self.normalize(value)
    cleaned = value.to_s.delete("^0-9")
    return nil unless cleaned.length == 13

    cleaned
  end

  def self.valid?(value)
    digits = normalize(value)
    return false if digits.nil?
    return false unless digits.match?(/\A[0-9]{13}\z/)

    digits == number_with_check_digit(digits[0, 12])
  end

  # Given the 12 first digits (string), returns the full 13-digit string
  # including the computed check digit.
  def self.number_with_check_digit(first12)
    return nil unless first12.match?(/\A[0-9]{12}\z/)

    first12 + check_digit(first12).to_s
  end

  def self.check_digit(first12)
    return nil unless first12.match?(/\A[0-9]{12}\z/)

    sum = first12.each_char.each_with_index.sum { |ch, i| ch.to_i * WEIGHTS[i % 2] }
    (10 - (sum % 10)) % 10
  end
  private_class_method :check_digit

  attr_reader :value

  def initialize(value)
    @value = value.to_s
  end

  def valid?
    self.class.valid?(value)
  end

  def digits
    self.class.normalize(value)
  end

  # Basic grouping: GS1 prefix (3 digits), dash, then the remaining 10 digits
  # (keeps the whole 13-digit number readable).
  def formatted
    d = digits
    return value unless d

    "#{d[0, 3]}-#{d[3, 10]}"
  end
end
