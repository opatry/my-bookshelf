module Admin
  class DashboardController < BaseController
    def index
      @read_count = owner.reviews.read.count
      @wishlist_count = owner.reviews.wishlist.count
      @ongoing = owner.reviews.ongoing.first
      @recent = owner.reviews.read.recent.limit(10)
      @books_count = Book.count
      @tags_count = Tag.count
      @series_count = Series.count
    end
  end
end
