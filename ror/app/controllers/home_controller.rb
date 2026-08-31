class HomeController < ApplicationController
  RECENT_MONTHS = 6
  RECENT_LIMIT = 6
  WISHLIST_PREVIEW = 6

  def index
    @ongoing_review = owner_reviews.ongoing.with_book.first
    # The ongoing showcase card spans 2 grid slots, so it displaces 2 of the
    # recent reads (in line with the static site: 4 reads + 1 ongoing = 6 slots).
    recent_limit = @ongoing_review ? RECENT_LIMIT - 2 : RECENT_LIMIT
    @recent_reviews = recent_reads(recent_limit)
    @wishlist_preview = owner_reviews.wishlist.with_book.order(:priority).limit(WISHLIST_PREVIEW)
  end

  private

  def recent_reads(limit)
    owner_reviews.read.with_book
                  .recent
                  .where(read_date: RECENT_MONTHS.months.ago..)
                  .limit(limit)
  end
end
