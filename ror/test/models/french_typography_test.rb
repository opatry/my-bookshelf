require "test_helper"

class FrenchTypographyTest < ActiveSupport::TestCase
  test "trims surrounding whitespace and collapses runs of spaces" do
    assert_equal "a b c", FrenchTypography.sanitize("  a   b  c  ")
  end

  test "replaces three dots with the ellipsis character" do
    assert_equal "Voilà…", FrenchTypography.sanitize("Voilà...")
  end

  test "replaces straight apostrophes with the curly one" do
    assert_equal "l’été", FrenchTypography.sanitize("l'été")
  end

  test "turns hyphen into an em dash" do
    assert_equal "a — b", FrenchTypography.sanitize("a - b")
  end

  test "uses a narrow no-break space before ; ! ?" do
    assert_equal "Un texte\u202F!", FrenchTypography.sanitize("Un texte !")
  end

  test "uses a no-break space before a colon" do
    assert_equal "Note\u00A0:", FrenchTypography.sanitize("Note :")
  end

  test "returns nil unchanged" do
    assert_nil FrenchTypography.sanitize(nil)
  end
end
