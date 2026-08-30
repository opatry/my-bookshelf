require "test_helper"

class Admin::ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.default_owner
    @book = books(:one)
  end

  test "new with an existing review redirects to the edit form" do
    get new_admin_book_review_path(@book)

    assert_redirected_to edit_admin_book_review_path(@book, @owner.reviews.find_by(book: @book))
  end

  test "new shows the form for a book without a review" do
    other = valid_book(title: "Sans critique", author: "Q")
    other.save!

    get new_admin_book_review_path(other)

    assert_response :success
    assert_select "form"
  end

  test "creates a read review" do
    other = valid_book(title: "Pour lecture", author: "Q")
    other.save!

    assert_difference -> { @owner.reviews.count } => 1 do
      post admin_book_reviews_path(other), params: {
        review: { status: "read", rating: 9, read_date: "2026-05-01", favorite: "1" }
      }
    end

    assert_redirected_to admin_book_path(other)
    review = @owner.reviews.find_by(book: other)
    assert_equal "read", review.status
    assert_equal 9, review.rating
    assert review.favorite
  end

  test "rejects an invalid review" do
    other = valid_book(title: "Pour lecture mauvaise", author: "Q")
    other.save!

    assert_no_difference -> { @owner.reviews.count } do
      post admin_book_reviews_path(other), params: {
        review: { status: "read", rating: nil, read_date: nil }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
  end

  test "updates a review status" do
    review = @owner.reviews.find_by(book: @book)

    patch admin_book_review_path(@book, review), params: {
      review: { status: "wishlist", priority: 2 }
    }

    assert_redirected_to admin_book_path(@book)
    review.reload
    assert_equal "wishlist", review.status
    assert_equal 2, review.priority
    assert_nil review.rating
    assert_nil review.read_date
  end

  test "destroys a review" do
    review = @owner.reviews.find_by(book: @book)

    assert_difference -> { @owner.reviews.count } => -1 do
      delete admin_book_review_path(@book, review)
    end

    assert_redirected_to admin_book_path(@book)
  end
end
