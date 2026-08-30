require "test_helper"

class BookTagTest < ActiveSupport::TestCase
  test "is valid with a book and a tag" do
    lt = BookTag.new(book: books(:one), tag: tags(:two))
    assert lt.valid?
  end

  test "requires a book" do
    lt = BookTag.new(tag: tags(:one))
    assert_not lt.valid?
    assert lt.errors.added?(:book, :blank)
  end

  test "requires a tag" do
    lt = BookTag.new(book: books(:one))
    assert_not lt.valid?
    assert lt.errors.added?(:tag, :blank)
  end

  test "pair of book and tag must be unique" do
    # books(:one) + tags(:one) already exists in the fixture
    dup = BookTag.new(book: books(:one), tag: tags(:one))
    assert_not dup.valid?
    assert dup.errors[:tag_id].present?
  end
end
