require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders the home page with library and recent sections" do
    owner = User.default_owner
    recent = valid_book(title: "Lecture récente", author: "Q")
    recent.save!
    owner.reviews.create!(book: recent, status: :read, rating: 7, read_date: Date.current.prev_month)

    get root_path

    assert_response :success
    assert_match I18n.t("home.section_recent"), response.body
    assert_match I18n.t("home.section_library"), response.body
    assert_select ".book-card__title", text: "Lecture récente"
  end

  test "renders the wishlist preview when the owner has wishlisted books" do
    owner = User.default_owner
    wished = valid_book(title: "Un souhait", author: "Q")
    wished.save!
    owner.reviews.create!(book: wished, status: :wishlist, priority: 1)

    get root_path

    assert_response :success
    assert_match I18n.t("home.section_wishlist"), response.body
    assert_select ".book-card__title", text: "Un souhait"
  end

  test "shows the ongoing reading section when the owner has an ongoing review" do
    owner = User.default_owner
    book = valid_book(title: "En cours", author: "Q")
    book.save!
    owner.reviews.create!(book: book, status: :ongoing)

    get root_path

    assert_response :success
    assert_match I18n.t("home.section_ongoing"), response.body
    assert_select ".current-reading__status", text: I18n.t("meta.ongoing")
  end

  test "ignores other users reviews on the public site" do
    # reviews(:two) belongs to Marie, not the default owner.
    get root_path

    assert_response :success
    assert_select ".book-card", count: 1 do
      assert_select ".book-card__title", text: "Le Comte de Monte-Cristo"
    end
    assert_select ".book-card__title", text: "Le Petit Prince", count: 0
  end
end
