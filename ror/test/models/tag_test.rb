require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "is valid with a name" do
    assert Tag.new(name: "Fantasy").valid?
  end

  test "requires a name" do
    tag = Tag.new(name: nil)
    assert_not tag.valid?
    assert tag.errors[:name].present?
  end

  test "name must be unique" do
    Tag.create!(name: "Fantasy")
    assert_not Tag.new(name: "Fantasy").valid?
  end

  test "auto-generates a slug from the name" do
    tag = Tag.new(name: "Space Opera")
    tag.valid?
    assert_equal "space-opera", tag.slug
  end

  test "slug must be unique" do
    Tag.create!(name: "Romance")
    dup = Tag.new(name: "Romance!")
    assert_not dup.valid?
    assert dup.errors[:slug].present?
  end

  test "has many books through book_tags" do
    tag = tags(:one)
    assert_equal [ books(:one) ], tag.books
  end
end
