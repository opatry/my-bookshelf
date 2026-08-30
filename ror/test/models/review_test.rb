require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def build_review(attrs = {})
    Review.new(
      # (user two, book one) is not used by any fixture
      { user: users(:two), book: books(:one), status: :read, rating: 8, read_date: Date.new(2026, 1, 15) }.merge(attrs)
    )
  end

  test "is valid for a read review with rating and date" do
    assert build_review.valid?
  end

  test "read review requires a rating" do
    review = build_review(rating: nil)
    assert_not review.valid?
    assert review.errors.added?(:rating, :blank)
  end

  test "read review requires a read_date" do
    review = build_review(read_date: nil)
    assert_not review.valid?
    assert review.errors.added?(:read_date, :blank)
  end

  test "rating must be within 1 and 10" do
    assert_not build_review(rating: 0).valid?
    assert_not build_review(rating: 11).valid?
  end

  test "ongoing review drops the rating" do
    review = build_review(status: :ongoing, rating: 8, read_date: nil)
    assert review.valid?
    assert_nil review.rating
  end

  test "ongoing review drops the read_date" do
    review = build_review(status: :ongoing, rating: nil, read_date: Date.new(2026, 1, 15))
    assert review.valid?
    assert_nil review.read_date
  end

  test "ongoing review is valid without rating or date" do
    assert build_review(status: :ongoing, rating: nil, read_date: nil).valid?
  end

  test "switching from read to wishlist drops the reading facts" do
    review = build_review(status: :wishlist, priority: 2)
    assert review.valid?
    assert_nil review.rating
    assert_nil review.read_date
  end

  test "switching from wishlist to read drops the priority" do
    review = build_review(status: :read, rating: 8, read_date: Date.new(2026, 1, 15), priority: 2)
    assert review.valid?
    assert_nil review.priority
  end

  test "wishlist review requires a priority" do
    review = build_review(status: :wishlist, rating: nil, read_date: nil, priority: nil)
    assert_not review.valid?
    assert review.errors[:priority].present?
  end

  test "wishlist review with a priority is valid" do
    assert build_review(status: :wishlist, rating: nil, read_date: nil, priority: 2).valid?
  end

  test "a user can review a book only once" do
    # reviews(:one) is user one + book one
    review = Review.new(user: users(:one), book: books(:one), status: :read, rating: 8, read_date: Date.new(2026, 2, 1))
    assert_not review.valid?
    assert review.errors[:book_id].present?
  end
end
