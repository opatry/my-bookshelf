class LastReadingsController < ApplicationController
  def index
    @reviews = owner_reviews.read.with_book.recent
  end
end
