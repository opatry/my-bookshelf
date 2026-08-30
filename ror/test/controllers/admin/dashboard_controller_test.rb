require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "renders the dashboard with owner stats" do
    get admin_root_path

    assert_response :success
    assert_select "h1", text: I18n.t("admin.dashboard.index.title")
    assert_select ".admin-stat__value", text: "1" # read review
    assert_select ".admin-stat__label", text: I18n.t("admin.dashboard.index.read_count")
    assert_select ".admin-list" do
      assert_select "a", text: "Le Comte de Monte-Cristo"
    end
  end

  test "404 when the default owner is missing" do
    User.destroy_all

    get admin_root_path

    assert_response :not_found
  end
end
