require "test_helper"

class SearchBooksTest < ActiveSupport::TestCase
  test "finds books by title" do
    results = SearchBooks.call("comte")

    assert_equal 1, results.size
    assert_equal "Le Comte de Monte-Cristo", results.first[:title]
  end

  test "finds books by author" do
    results = SearchBooks.call("Alexandre")

    assert_equal 1, results.size
    assert_equal "Le Comte de Monte-Cristo", results.first[:title]
  end

  test "finds books by tag" do
    results = SearchBooks.call("thriller")

    assert_equal 1, results.size
    assert_equal [ "Thriller" ], results.first[:tags]
  end

  test "returns an empty array for short queries" do
    assert_equal [], SearchBooks.call("a")
  end

  test "returns an empty array for unmatched queries" do
    assert_equal [], SearchBooks.call("zzzzz")
  end

  test "only searches the default owner books" do
    # book two has no default-owner review (Marie reviewed it).
    assert_equal [], SearchBooks.call("Petit")
  end
end
