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

  test "searches the whole catalog, including books the owner has not reviewed" do
    # book two has no default-owner review (Marie reviewed it) but is in the catalog.
    results = SearchBooks.call("Petit")

    assert_equal 1, results.size
    assert_equal "Le Petit Prince", results.first[:title]
  end

  test "matches tagless books by title or author" do
    valid_book(
      isbn: "9782070368228",
      title: "L’Étranger",
      author: "Albert Camus"
    ).tap(&:save!)

    assert_equal [ "L’Étranger" ], SearchBooks.call("Camus").map { |r| r[:title] }
  end

  test "is accent-insensitive" do
    valid_book(
      isbn: "9782070368228",
      title: "L’Étranger",
      author: "Albert Camus"
    ).tap(&:save!)

    assert_equal [ "L’Étranger" ], SearchBooks.call("etranger").map { |r| r[:title] }
    assert_equal [ "L’Étranger" ], SearchBooks.call("Étranger").map { |r| r[:title] }
  end

  test "is apostrophe-insensitive" do
    valid_book(
      isbn: "9782070368228",
      title: "L’Étranger",
      author: "Albert Camus"
    ).tap(&:save!)

    assert_equal [ "L’Étranger" ], SearchBooks.call("L'Étranger").map { |r| r[:title] }
  end
end
