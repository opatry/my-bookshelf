require "test_helper"

class SeriesTest < ActiveSupport::TestCase
  test "is valid with a name" do
    assert Series.new(name: "Le Cycle d’Hyperion").valid?
  end

  test "requires a name" do
    series = Series.new(name: nil)
    assert_not series.valid?
    assert series.errors.added?(:name, :blank)
  end

  test "name must be unique" do
    Series.create!(name: "Hyperion")
    assert_not Series.new(name: "Hyperion").valid?
  end

  test "titleizes and sanitizes the name" do
    series = Series.new(name: "  le   cycle d'hyperion  ")
    series.valid?
    assert_equal "Le Cycle D’hyperion", series.name
  end

  test "has many books" do
    series = series(:one)
    assert series.books.include?(books(:one))
  end
end
