class TagsController < ApplicationController
  def index
    counts = owner_reviews.joins(book: :tags).group("tags.id").count
    @tags = Tag.order(:name).map { |tag| [ tag, counts[tag.id] || 0 ] }.select { |_, count| count.positive? }
  end

  def show
    @tag = Tag.find_by!(slug: params[:id])
    @reviews = owner_reviews.read.with_book
                             .joins(book: :tags)
                             .where(tags: { id: @tag.id })
                             .recent
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Tag not found"
  end
end
