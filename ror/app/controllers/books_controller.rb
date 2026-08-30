class BooksController < ApplicationController
  def show
    @book = Book.find(params[:id].to_i)
    @review = owner_reviews.find_by(book: @book)
    @same_series = @book.series ? @book.series.books.where.not(id: @book.id).order(:title) : []
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Book not found"
  end
end
