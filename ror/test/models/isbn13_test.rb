require "test_helper"

class Isbn13Test < ActiveSupport::TestCase
  test "is valid for a correct isbn" do
    assert Isbn13.valid?("9782070373017")
    assert Isbn13.valid?("9782226317179")
  end

  test "is invalid for a wrong checksum" do
    assert_not Isbn13.valid?("9782070373018")
  end

  test "is invalid for a short value" do
    assert_not Isbn13.valid?("123")
  end

  test "is invalid for a blank value" do
    assert_not Isbn13.valid?("")
    assert_not Isbn13.valid?(nil)
  end

  test "ignores hyphens and spaces in input" do
    assert Isbn13.valid?("978-2-070373-0 1-7")
  end

  test "computes the check digit" do
    first12 = "978222631717"
    full = Isbn13.number_with_check_digit(first12)
    assert_equal "9782226317179", full
    assert_equal "9", full[-1]
  end

  test "formats with GS1 prefix grouping" do
    assert_equal "978-2070373017", Isbn13.new("9782070373017").formatted
  end

  test "formatted returns the raw value when invalid" do
    assert_equal "123", Isbn13.new("123").formatted
  end
end
