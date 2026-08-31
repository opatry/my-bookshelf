require "test_helper"

class Admin::BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
  end

  test "index lists books" do
    get admin_books_path

    assert_response :success
    assert_select "table tbody tr", count: Book.count
    assert_select "a", text: @book.title
  end

  test "new renders the form" do
    get new_admin_book_path

    assert_response :success
    assert_select "form"
  end

  test "create a book with resolved tags" do
    assert_difference -> { Book.count } => 1 do
      post admin_books_path, params: {
        book: {
          title: "Candide", author: "Voltaire", isbn: unique_isbn,
          publication_year: 1759, page_count: 208,
          description: "Tout est pour le mieux.",
          tag_names: "Classique, Philosophie",
          cover: fixture_file_upload("cover.jpg", "image/jpeg")
        }
      }
    end

    book = Book.order(:created_at).last
    assert_redirected_to admin_book_path(book)
    assert_equal "Candide", book.title
    assert book.cover.attached?
    assert_equal [ "Classique", "Philosophie" ], book.tags.order(:name).pluck(:name)
    assert_equal I18n.t("admin.books.create.success"), flash[:notice]
  end

  test "rejects a book without a cover" do
    assert_no_difference -> { Book.count } do
      post admin_books_path, params: {
        book: { title: "Sans couverture", author: "Personne", isbn: unique_isbn }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
  end

  test "rejects a book with an invalid ISBN and re-renders" do
    assert_no_difference -> { Book.count } do
      post admin_books_path, params: {
        book: { title: "Mauvais", author: "Personne", isbn: "1234567890123" }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
  end

  test "updates a book" do
    patch admin_book_path(@book), params: {
      book: { title: "Le Comte (rééd.)", author: @book.author, isbn: @book.isbn, tag_names: "Classique" }
    }

    @book.reload
    assert_redirected_to admin_book_path(@book)
    assert_equal "Le Comte (rééd.)", @book.title
    assert_equal [ "Classique" ], @book.tags.pluck(:name)
  end

  test "destroys a book" do
    assert_difference -> { Book.count } => -1 do
      delete admin_book_path(@book)
    end

    assert_redirected_to admin_books_path
  end
end
