require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  test "shows the month groups for a year" do
    get calendar_path(year: 2026)

    assert_response :success
    assert_select "h2", text: I18n.l(Date.new(2026, 1, 1), format: "%B %Y")
    assert_select ".calendar-day__title", text: "Le Comte de Monte-Cristo"
  end

  test "does not include reviews of other years" do
    get calendar_path(year: 2025)

    assert_response :success
    assert_select ".calendar-day", count: 0
    assert_select ".empty-state"
  end

  test "rejects non-numeric years" do
    get "/calendar/abcd"

    assert_response :not_found
  end
end
