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
      assert_select ".wish-priority", text: "#2"
      # The two owned entries are the fixture's none here (no wishlist read fixture)
      assert_select ".book-card", count: 1
    end
  end

  test "does not include read books" do
    get wishlist_path

    assert_response :success
    assert_select ".book-card", count: 0
  end
end
