require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  test "shows a month table for the year" do
    get calendar_path(year: 2026)

    assert_response :success
    assert_select ".month-block h2", text: /^Janvier/
    assert_select "table.month-table td.day-cell a[title*=Monte-Cristo]"
    assert_select ".rating-overlay", text: /8/
  end

  test "does not include reviews of other years" do
    get calendar_path(year: 2025)

    assert_response :success
    assert_select "td.day-cell a", count: 0
    assert_select ".empty-state"
  end

  test "hides the previous/next links at the reading-range boundaries" do
    reviews(:one).update!(read_date: Date.new(2025, 1, 10))

    get calendar_path(year: 2025)
    assert_response :success
    assert_select "nav.calendar-year-nav a", count: 1
    assert_select "nav.calendar-year-nav a[href=?]", calendar_path(year: 2026), count: 1

    get calendar_path(year: 2026)
    assert_response :success
    assert_select "nav.calendar-year-nav a", count: 1
    assert_select "nav.calendar-year-nav a[href=?]", calendar_path(year: 2025), count: 1
  end

  test "does not offer navigation below the earliest reading year" do
    reviews(:one).update!(read_date: Date.new(2025, 1, 10))

    get calendar_path(year: 2024)
    assert_response :success
    assert_select "nav.calendar-year-nav a", count: 1
    assert_select "nav.calendar-year-nav a[href=?]", calendar_path(year: 2023), count: 0
  end

  test "redirects future years to the current year" do
    get calendar_path(year: Time.current.year + 1)

    assert_redirected_to calendar_path(year: Time.current.year)
  end

  test "rejects non-numeric years" do
    get "/calendar/abcd"

    assert_response :not_found
  end
end
