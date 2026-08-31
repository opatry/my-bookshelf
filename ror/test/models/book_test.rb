require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "is valid with all required fields" do
    assert valid_book.valid?
  end

  test "requires a title" do
    book = valid_book(title: nil)
    assert_not book.valid?
    assert book.errors.added?(:title, :blank)
  end

  test "requires an author" do
    book = valid_book(author: nil)
    assert_not book.valid?
    assert book.errors.added?(:author, :blank)
  end

  test "requires an isbn" do
    book = valid_book(isbn: nil)
    assert_not book.valid?
    assert book.errors.added?(:isbn, :blank)
  end

  test "rejects an invalid isbn" do
    book = valid_book(isbn: "123")
    assert_not book.valid?
    assert book.errors.added?(:isbn, :invalid_isbn)
  end

  test "accepts an isbn with valid checksum" do
    isbn = unique_isbn
    assert Isbn13.valid?(isbn)
    book = Book.new(isbn: isbn, title: "T", author: "A")
    assert book.valid?
  end

  test "isbn must be unique" do
    isbn = unique_isbn
    Book.create!(isbn: isbn, title: "T", author: "A")
    dup = Book.new(isbn: isbn, title: "U", author: "B")
    assert_not dup.valid?
    assert dup.errors[:isbn].present?
  end

  test "sanitizes title author and description" do
    book = valid_book(title: "  L'été   des orages...  ", author: "  A.  Dumas  ",
                      description: "Une description !")
    book.valid? # triggers the sanitizing before_validation
    assert_equal "L’été des orages…", book.title
    assert_equal "A. Dumas", book.author
    assert_includes book.description, "Une description\u202F!"
  end

  test "series is optional" do
    assert valid_book(series: nil).valid?
  end

  test "belongs to series" do
    series = series(:one)
    book = valid_book(series: series)
    assert_equal series, book.series
  end

  test "formatted_isbn groups the GS1 prefix" do
    book = valid_book(isbn: "9782070373017")
    assert_equal "978-2070373017", book.formatted_isbn
  end

  test "computes search_text on save, accent and apostrophe normalized" do
    book = valid_book(title: "L’Étranger", author: "Albert Camus")
    book.save!

    assert_equal "l etranger albert camus", book.search_text
  end

  test "recomputes search_text when tags change" do
    book = valid_book(title: "La Peste", author: "Albert Camus")
    book.tags = [ tags(:one) ]
    book.save!

    assert_includes book.search_text, "thriller"

    book.tags = []
    book.save!

    assert_not_includes book.search_text, "thriller"
  end
end
