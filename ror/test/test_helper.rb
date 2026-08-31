ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # SQLite fixture tests with unique ISBNs derived from a per-process counter
    # are flaky under parallelization (shared test DB). Keep it deterministic.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # A cover is mandatory for books, so give the fixture books one before each
    # test (the demo test image is a tiny real JPEG under test/fixtures/files/).
    setup do
      Book.where.missing(:cover_attachment).find_each do |book|
        book.cover.attach(
          io: File.open(Rails.root.join("test/fixtures/files/cover.jpg")),
          filename: "cover.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    # Add more helper methods to be used by all tests here...
    def unique_isbn
      @isbn_counter = @isbn_counter.to_i + 1
      # Unique across processes too, in case parallelization is ever re-enabled.
      pid_prefix = Process.pid % 1000
      Isbn13.number_with_check_digit(format("%03d%09d", pid_prefix, @isbn_counter))
    end

    def valid_book(attrs = {})
      book = Book.new(
        { isbn: unique_isbn, title: "Un livre", author: "Un auteur" }.merge(attrs)
      )
      book.cover.attach(
        io: File.open(Rails.root.join("test/fixtures/files/cover.jpg")),
        filename: "cover.jpg", content_type: "image/jpeg"
      )
      book
    end
  end
end
