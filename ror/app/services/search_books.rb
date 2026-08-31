# Server-side search over the whole book catalog (title, author, tags),
# used by the AJAX search endpoint. Search covers every book, whether or not
# the default owner has reviewed (read, ongoing, or wished) it.
#
# Matching is accent- and apostrophe-insensitive (same behaviour as the original
# Fuse.js `ignoreDiacritics`): the query is normalized in Ruby with
# `SearchNormalizer` and compared against the denormalized `search_text`
# column, so "etranger" matches "Étranger" and "L'Étranger" matches "L’Étranger".
class SearchBooks
  MIN_QUERY_LENGTH = 2

  def self.call(query)
    new(query).results
  end

  def initialize(query)
    @query = query.to_s
  end

  def results
    return [] if @query.strip.length < MIN_QUERY_LENGTH

    matching_books.map { |book| serialize(book) }
  end

  private

  def matching_books
    books = Book.all

    SearchNormalizer.normalize(@query).split(/\s+/).each do |token|
      books = books.where("books.search_text LIKE ?", "%#{token}%")
    end

    books.order(:title).limit(12)
  end

  def serialize(book)
    {
      id: book.id,
      title: book.title,
      author: book.author,
      url: Rails.application.routes.url_helpers.book_path(book),
      tags: book.tags.order(:name).pluck(:name)
    }
  end
end
