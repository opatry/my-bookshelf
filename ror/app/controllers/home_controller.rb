class HomeController < ApplicationController
  RECENT_MONTHS = 6
  RECENT_LIMIT = 6
  WISHLIST_PREVIEW = 6

  def index
    @ongoing_review = owner_reviews.ongoing.with_book.first
    @recent_reviews = recent_reads(RECENT_LIMIT)
    @wishlist_preview = owner_reviews.wishlist.with_book.order(:priority).limit(WISHLIST_PREVIEW)
    @library = owner_reviews.read.with_book
  end

  private

  def recent_reads(limit)
    owner_reviews.read.with_book
                  .recent
                  .where(read_date: RECENT_MONTHS.months.ago..)
                  .limit(limit)
  end
end
