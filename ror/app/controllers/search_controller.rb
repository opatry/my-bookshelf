class SearchController < ApplicationController
  def index
    @results = SearchBooks.call(params[:q])
    render json: { results: @results }, status: :ok
  end
end
