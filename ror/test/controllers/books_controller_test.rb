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
    assert_select "h2.book-detail__section-title", text: "4e de couverture"
    assert_select ".book-detail__description", text: /Un classique de la littérature\./
    assert_select ".book-tags .tag", text: "Thriller"
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
      assert_select ".book-details", text: /Priorité 1/
    end
  end

  test "404 for an unknown book" do
    get "/books/999999"

    assert_response :not_found
  end
end
