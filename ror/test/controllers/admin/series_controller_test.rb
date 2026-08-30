require "test_helper"

class Admin::SeriesControllerTest < ActionDispatch::IntegrationTest
  test "index lists series" do
    get admin_series_index_path

    assert_response :success
    assert_select "table tbody tr", count: Series.count
  end

  test "creates a series" do
    assert_difference -> { Series.count } => 1 do
      post admin_series_index_path, params: { series: { name: "cycle de fondation" } }
    end

    series = Series.last
    assert_equal "Cycle De Fondation", series.name
    assert_redirected_to admin_series_index_path
  end

  test "updates a series" do
    series = series(:one)

    patch admin_series_path(series), params: { series: { name: "Série Un (remaniée)" } }

    assert_redirected_to admin_series_index_path
    assert_equal "Série Un (Remaniée)", series.reload.name
  end

  test "destroys a series and unlinks its books" do
    series = Series.create!(name: "Série éphémère")
    orphan = valid_book(title: "Orphelin", author: "Q", series: series)
    orphan.save!

    assert_difference -> { Series.count } => -1 do
      delete admin_series_path(series)
    end

    assert_redirected_to admin_series_index_path
    assert_nil orphan.reload.series_id
  end
end
