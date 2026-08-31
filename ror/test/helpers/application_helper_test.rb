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

  test "book_metadata uses the lowercase pending phrases for the book page" do
    book = Book.new(title: "T", author: "A", page_count: 583, publication_year: 2017)

    assert_includes book_metadata(book, Review.new(status: :wishlist, priority: 1)).join(", "),
                    "dans les envies de lecture pour plus tard…"
    assert_includes book_metadata(book, Review.new(status: :ongoing)).join(", "),
                    "📖 en cours de lecture…"
  end

  test "capitalize_first uppercases the first letter, skipping a leading emoji" do
    assert_equal "📖 En cours de lecture…", capitalize_first("📖 en cours de lecture…")
    assert_equal "Dans les envies…", capitalize_first("dans les envies…")
  end

  test "shared book card shows the pending phrases instead of priority values" do
    book = books(:one)
    wishlist = Review.new(book: book, user: users(:one), status: :wishlist, priority: 2)
    ongoing = Review.new(book: book, user: users(:one), status: :ongoing)

    wishlist_html = render(partial: "shared/book_card", locals: { review: wishlist })
    assert_includes wishlist_html, "les envies de lecture pour plus tard"
    assert_not_includes wishlist_html, "#2"

    ongoing_html = render(partial: "shared/book_card", locals: { review: ongoing })
    assert_includes ongoing_html, "En cours de lecture"
  end

  test "read_on_month_label is lowercase and renders a real time element" do
    date = Date.new(2026, 1, 15)

    html = read_on_month_label(date)

    assert html.start_with?("lu en ")
    assert_includes html, '<time datetime="2026-01-15">'
    assert_includes html, "janvier 2026"
    assert html.html_safe?
    assert_not_includes html, "&lt;time"
  end

  test "capitalized_read_on_month_label is uppercase for the standalone card" do
    date = Date.new(2026, 1, 15)

    html = capitalized_read_on_month_label(date)

    assert html.start_with?("Lu en ")
    assert_includes html, '<time datetime="2026-01-15">'
    assert html.html_safe?
  end

  test "cover_tag falls back to a placeholder without a cover" do
    book = Book.new(title: "Sans couverture", author: "Une autrice")

    html = cover_tag(book)
    assert_includes html, "cover--placeholder"
  end
end
