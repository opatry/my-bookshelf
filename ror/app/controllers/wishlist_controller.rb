class WishlistController < ApplicationController
  def index
    @reviews = owner_reviews.wishlist.with_book.order(:priority)
  end
end
