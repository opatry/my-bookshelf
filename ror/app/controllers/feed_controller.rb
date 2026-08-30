class FeedController < ApplicationController
  before_action :set_headers

  def index
    @reviews = owner_reviews.read.with_book.recent.limit(20)
    @updated_at = @reviews.filter_map(&:read_date).max
  end

  private

  def set_headers
    response.headers["Content-Type"] = "application/atom+xml; charset=utf-8"
  end
end
