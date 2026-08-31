require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  test "shows a book with its review and covers" do
    book = books(:one)

    get book_path(book)

    assert_response :success
    assert_select "h2.book-title", text: /^#{Regexp.escape(book.title)}/
    assert_select ".book-detail__author", text: book.author
    assert_select ".rating-bar .star-icon" do
      assert_select ".icon-active", count: book.reviews.first.rating
      assert_select ".icon-inactive", count: 10 - book.reviews.first.rating
    end
    assert_select ".book-details time[datetime=?]", "2026-01-15"
    assert_select ".book-details", text: /lu en/
    assert_select ".book-detail__description", text: /Un classique de la littérature\./
    assert_select ".book-tags .tag", text: "Thriller"
    assert_select 'meta[property="og:type"][content="book"]'
    assert_select 'meta[property="book:author"][content=?]', book.author
    assert_select 'meta[property="book:isbn"][content=?]', book.isbn
    assert_select 'meta[property="book:release_date"][content=?]', "1844"
    assert_select 'meta[property="og:url"]' do
      assert_select "meta[content*='#{book_path(book)}']"
    end
    assert_select 'meta[property="og:description"][content=?]', book.description
  end

  test "includes the cover in Open Graph metadata for a book with a cover" do
    book = valid_book(title: "Un livre avec couverture", author: "Quelqu’un")
    book.save!

    get book_path(book)

    assert_response :success
    assert_select 'meta[property="og:image"][content*="/rails/active_storage/"]'
  end

  test "accepts the id-slug URL form" do
    book = books(:one)

    get "/books/#{book.id}-monte-cristo"

    assert_response :success
    assert_select "h2.book-title", text: /^#{Regexp.escape(book.title)}/
  end

  test "accepts the bare id URL" do
    get "/books/#{books(:one).id}"

    assert_response :success
  end

  test "shows the wishlist state for a wished book" do
    owner = User.default_owner
    wished_book = valid_book(title: "Un souhait", author: "Quelqu’un")
    Book.transaction do
      wished_book.save!
      owner.reviews.create!(book: wished_book, status: :wishlist, priority: 1)

      get book_path(wished_book)

      assert_response :success
      assert_select ".book-details", text: /dans les envies de lecture pour plus tard…/
    end
  end

  test "404 for an unknown book" do
    get "/books/999999"

    assert_response :not_found
  end
end
