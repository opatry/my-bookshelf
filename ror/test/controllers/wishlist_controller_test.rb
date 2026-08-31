require "test_helper"

class WishlistControllerTest < ActionDispatch::IntegrationTest
  test "lists the owner wishlist ordered by priority" do
    owner = User.default_owner
    low = valid_book(title: "Priorité basse", author: "Autrice")
    Book.transaction do
      low.save!
      owner.reviews.create!(book: low, status: :wishlist, priority: 2)

      get wishlist_path

      assert_response :success
      assert_select ".book-title", text: "Priorité basse"
      # The priority value is shown on the card (the full phrase lives on the book page).
      assert_select ".book-footer p", text: /Priorité #2/
      assert_select ".wish-priority[data-priority='2']", text: "#2"
      # The two owned entries are the fixture's none here (no wishlist read fixture)
      assert_select ".book-card", count: 1
    end
  end

  test "shows the priority value on a wished book card" do
    owner = User.default_owner
    book = valid_book(title: "Mon envie", author: "Autrice").tap(&:save!)
    owner.reviews.create!(book: book, status: :wishlist, priority: 3)

    get wishlist_path

    assert_response :success
    assert_select ".book-footer p", text: /Priorité #3/
    assert_select ".wish-priority[data-priority='3']", text: "#3"
  end

  test "does not include read books" do
    get wishlist_path

    assert_response :success
    assert_select ".book-card", count: 0
  end
end
