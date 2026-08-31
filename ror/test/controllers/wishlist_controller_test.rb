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
      # The priority is not displayed as a value but as the pending phrase.
      assert_select ".book-footer p", text: /dans les envies de lecture pour plus tard…/i
      assert_select ".wish-priority", count: 0
      # The two owned entries are the fixture's none here (no wishlist read fixture)
      assert_select ".book-card", count: 1
    end
  end

  test "shows the wishlist pending phrase on a wished book card" do
    owner = User.default_owner
    book = valid_book(title: "Mon envie", author: "Autrice").tap(&:save!)
    owner.reviews.create!(book: book, status: :wishlist, priority: 3)

    get wishlist_path

    assert_response :success
    assert_select ".book-footer p", text: /dans les envies de lecture pour plus tard…/i
    assert_select ".book-footer p", text: /#[0-9]/, count: 0
  end

  test "does not include read books" do
    get wishlist_path

    assert_response :success
    assert_select ".book-card", count: 0
  end
end
