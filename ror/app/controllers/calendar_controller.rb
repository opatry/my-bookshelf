class CalendarController < ApplicationController
  def show
    @year = params[:year].to_i
    @reviews = owner_reviews.read.with_book
                            .where(read_date: Date.new(@year, 1, 1)..Date.new(@year, 12, 31))
                            .order(read_date: :asc)
  end
end
