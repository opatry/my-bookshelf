require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  test "shows a book with its review and covers" do
    book = books(:one)

    get book_path(book)

    assert_response :success
    assert_select "h1", text: book.title
    assert_select ".book-detail__author", text: book.author
    assert_select ".book-detail__review" do
      assert_select ".stars"
    end
    assert_select ".book-detail__back-cover", text: /À dix-neuf ans, une lettre dénonce Edmond Dantès\./
    assert_select ".tag", text: "Thriller"
  end

  test "accepts the id-slug URL form" do
    book = books(:one)

    get "/books/#{book.id}-monte-cristo"

    assert_response :success
    assert_select "h1", text: book.title
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
      assert_select ".book-detail__review", text: /#{I18n.t("books.show.wishlist")}/
    end
  end

  test "404 for an unknown book" do
    get "/books/999999"

    assert_response :not_found
  end
end
