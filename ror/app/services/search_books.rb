# Server-side search across the default owner's books (title, author, tags),
# used by the AJAX search endpoint. Phase 1 is single-user: we only search the
# books the default owner has reviewed.
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
    tokens = @query.split(/\s+/)
    books = Book.joins(:tags).where(id: owned_book_ids).distinct

    tokens.each do |token|
      pattern = "%#{token.downcase}%"
      books = books.where(
        "LOWER(books.title) LIKE :p OR LOWER(books.author) LIKE :p OR LOWER(tags.name) LIKE :p", p: pattern
      )
    end

    books.order(:title).limit(12)
  end

  def owned_book_ids
    owner ? owner.reviews.select(:book_id) : []
  end

  def owner
    @owner ||= User.default_owner
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
