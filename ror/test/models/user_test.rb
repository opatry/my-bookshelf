require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with name email and password" do
    user = User.new(name: "Olivier", email: "o@example.org", password: "secret123")
    assert user.valid?
  end

  test "requires a name" do
    user = User.new(name: nil, email: "o@example.org", password: "secret123")
    assert_not user.valid?
    assert user.errors.added?(:name, :blank)
  end

  test "requires an email" do
    user = User.new(name: "Olivier", email: nil, password: "secret123")
    assert_not user.valid?
    assert user.errors.added?(:email, :blank)
  end

  test "email must be unique" do
    User.create!(name: "Olivier", email: "o@example.org", password: "secret123")
    dup = User.new(name: "Marie", email: "o@example.org", password: "secret123")
    assert_not dup.valid?
    assert dup.errors[:email].present?
  end

  test "authenticates with the correct password" do
    user = User.create!(name: "Olivier", email: "o@example.org", password: "secret123")
    assert user.authenticate("secret123")
    assert_not user.authenticate("wrong")
  end

  test "has many reviews and books through reviews" do
    user = users(:one)
    assert_equal [books(:one)], user.books
    assert_equal [reviews(:one)], user.reviews
  end
end
