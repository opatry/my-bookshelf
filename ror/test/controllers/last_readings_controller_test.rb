require "test_helper"

class LastReadingsControllerTest < ActionDispatch::IntegrationTest
  test "lists the owner read reviews grouped by year" do
    get last_readings_path

    assert_response :success
    assert_select ".book-title", text: "Le Comte de Monte-Cristo"
    assert_select "h2", text: /^2026 /
  end

  test "does not include wishlist or other user reviews" do
    get last_readings_path

    assert_response :success
    assert_select ".book-card", count: 1
  end
end
