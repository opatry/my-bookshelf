require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders the home page with recent sections" do
    owner = User.default_owner
    recent = valid_book(title: "Lecture récente", author: "Q")
    recent.save!
    owner.reviews.create!(book: recent, status: :read, rating: 7, read_date: Date.current.prev_month)

    get root_path

    assert_response :success
    assert_match I18n.t("home.section_recent"), response.body
    assert_select ".book-title", text: "Lecture récente"
  end

  test "renders the wishlist preview when the owner has wishlisted books" do
    owner = User.default_owner
    wished = valid_book(title: "Un souhait", author: "Q")
    wished.save!
    owner.reviews.create!(book: wished, status: :wishlist, priority: 1)

    get root_path

    assert_response :success
    assert_match I18n.t("home.section_wishlist"), response.body
    assert_select ".book-title", text: "Un souhait"
  end

  test "shows the ongoing reading as a showcase card" do
    owner = User.default_owner
    book = valid_book(title: "En cours", author: "Q")
    book.save!
    owner.reviews.create!(book: book, status: :ongoing)

    get root_path

    assert_response :success
    assert_select "#recent-books .book-showcase h2 a", text: "En cours"
  end

  test "holds up to six books in the recent reads section" do
    owner = User.default_owner
    books = 6.times.map { |i| valid_book(title: "Récente #{i}", author: "Q").tap(&:save!) }
    books.each_with_index do |book, i|
      owner.reviews.create!(book: book, status: :read, rating: 7, read_date: Date.current - (i + 1).days)
    end

    get root_path

    assert_response :success
    assert_select "#recent-books .book-card.read", count: 6
    assert_select "#recent-books .book-showcase", count: 0
  end

  test "makes room for the ongoing showcase in the recent reads section" do
    owner = User.default_owner
    ongoing = valid_book(title: "En cours", author: "Q").tap(&:save!)
    owner.reviews.create!(book: ongoing, status: :ongoing)
    books = 6.times.map { |i| valid_book(title: "Récente #{i}", author: "Q").tap(&:save!) }
    books.each_with_index do |book, i|
      owner.reviews.create!(book: book, status: :read, rating: 7, read_date: Date.current - (i + 1).days)
    end

    get root_path

    assert_response :success
    assert_select "#recent-books .book-showcase", count: 1
    assert_select "#recent-books .book-card.read", count: 4
  end

  test "shows the ongoing showcase card without a priority value" do
    owner = User.default_owner
    book = valid_book(title: "En cours", author: "Q").tap(&:save!)
    owner.reviews.create!(book: book, status: :ongoing)

    get root_path

    assert_response :success
    assert_select "#recent-books .book-showcase h2 a", text: "En cours"
    assert_select "#recent-books .book-showcase", text: /#[0-9]/, count: 0
  end

  test "ignores other users reviews on the public site" do
    owner = User.default_owner
    mine = valid_book(title: "Mon livre", author: "Q").tap(&:save!)
    owner.reviews.create!(book: mine, status: :read, rating: 7, read_date: Date.current.prev_day)

    marie = users(:two)
    theirs = valid_book(title: "Livre de Marie", author: "Q").tap(&:save!)
    marie.reviews.create!(book: theirs, status: :read, rating: 7, read_date: Date.current.prev_day)

    get root_path

    assert_response :success
    assert_select "#recent-books .book-title", text: "Mon livre"
    assert_select "#recent-books .book-title", text: "Livre de Marie", count: 0
  end
end
