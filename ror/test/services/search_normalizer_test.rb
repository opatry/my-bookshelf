require "test_helper"

class SearchNormalizerTest < ActiveSupport::TestCase
  test "strips diacritics and downcases" do
    assert_equal "etranger", SearchNormalizer.normalize("Étranger")
    assert_equal "l ecume des jours", SearchNormalizer.normalize("L’Écume des jours")
  end

  test "unifies curly and straight apostrophes" do
    assert_equal SearchNormalizer.normalize("L’Étranger"), SearchNormalizer.normalize("L'Étranger")
  end

  test "collapses whitespace" do
    assert_equal "albert camus", SearchNormalizer.normalize("  Albert    Camus ")
  end

  test "handles nil and empty" do
    assert_equal "", SearchNormalizer.normalize(nil)
    assert_equal "", SearchNormalizer.normalize("")
  end
end
