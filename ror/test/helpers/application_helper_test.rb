require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "page_title uses the site name when no content is set for title" do
    assert_equal I18n.t("site.name"), page_title
  end

  test "read_date_label formats the read date" do
    review = reviews(:one)

    assert_equal I18n.t("meta.read_on", date: I18n.l(review.read_date, format: :long)), read_date_label(review)
  end

  test "page_count_label pluralizes page counts" do
    book = books(:one)

    assert_equal I18n.t("meta.pages", count: book.page_count), page_count_label(book)
  end

  test "star_rating renders the 10-star scale" do
    review = reviews(:one)

    html = star_rating(review)
    assert_equal 10, html.scan("star-icon").size
    assert_equal review.rating, html.scan("icon-active").size
    assert_equal 10 - review.rating, html.scan("icon-inactive").size
  end

  test "book_metadata mixes book facts and the review state" do
    review = reviews(:one)
    metadata = book_metadata(review.book, review)

    assert_includes metadata, I18n.t("meta.read_on_month", date: pretty_read_date(review.read_date))
    assert_includes metadata, I18n.t("meta.pages", count: review.book.page_count)
  end

  test "cover_tag falls back to a placeholder without a cover" do
    book = books(:one)

    html = cover_tag(book)
    assert_includes html, "cover--placeholder"
  end
end
