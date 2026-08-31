require "test_helper"

class LastReadingsControllerTest < ActionDispatch::IntegrationTest
  test "lists the owner read reviews grouped by year" do
    get last_readings_path

    assert_response :success
    assert_select ".book-title", text: "Le Comte de Monte-Cristo"
    assert_select "h2", text: /^2026/
  end

  test "shows the calendar matrix and year navigation" do
    get last_readings_path

    assert_response :success
    assert_select "table.calendar"
    assert_select ".calendar-cell", minimum: 12
    assert_select ".month-section .title-more a[title=?]", "Retour en haut de page"
    assert_select "a[href=?]", calendar_path(year: 2026)
  end

  test "summarizes the year counts and pages instead of a permanent label" do
    get last_readings_path

    assert_response :success
    assert_select ".year-section > h2", count: 1
    assert_select ".year-section > h2", text: /livres?/, count: 1
    assert_select ".year-section > h2", text: /pages/, count: 1
    assert_select ".year-section > h2", text: /Bibliothèque/, count: 0
  end

  test "does not include wishlist or other user reviews" do
    get last_readings_path

    assert_response :success
    assert_select ".month-section .book-card", count: 1
  end
end
