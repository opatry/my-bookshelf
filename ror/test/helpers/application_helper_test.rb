require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "page_title uses the site name when no content is set for title" do
    assert_equal I18n.t("site.name"), page_title
  end

  test "nav_links renders the French navigation" do
    html = nav_links

    assert_match I18n.t("nav.home"), html
    assert_match I18n.t("nav.last_readings"), html
    assert_match I18n.t("nav.wishlist"), html
    assert_match I18n.t("nav.tags"), html
    assert_match I18n.t("nav.calendar"), html
  end

  test "read_date_label formats the read date" do
    review = reviews(:one)

    assert_equal I18n.t("meta.read_on", date: I18n.l(review.read_date, format: :long)), read_date_label(review)
  end

  test "page_count_label pluralizes page counts" do
    book = books(:one)

    assert_equal I18n.t("meta.pages", count: book.page_count), page_count_label(book)
  end

  test "star_rating renders 5 stars" do
    review = reviews(:one)

    html = star_rating(review)
    assert_match "★", html
    assert_match "☆", html
  end

  test "cover_tag falls back to a placeholder without a cover" do
    book = books(:one)

    html = cover_tag(book)
    assert_includes html, "cover--placeholder"
  end
end
