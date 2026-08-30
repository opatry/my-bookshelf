class SearchController < ApplicationController
  def index
    @results = SearchBooks.call(params[:q]).map do |result|
      book = Book.find(result[:id])
      result.merge(cover: book.cover.attached? ? url_for(book.cover.variant(:mini)) : nil)
    end
    render json: { results: @results }, status: :ok
  end
end
