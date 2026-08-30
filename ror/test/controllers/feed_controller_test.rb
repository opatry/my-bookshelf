require "test_helper"

class FeedControllerTest < ActionDispatch::IntegrationTest
  test "serves an atom feed of the latest owner read reviews" do
    get feed_path(format: :xml)

    assert_response :success
    assert_equal "application/atom+xml; charset=utf-8", response.headers["Content-Type"]
    assert_match /application\/atom\+xml/, response.content_type
    assert_select "feed title", text: I18n.t("feed.title", site: I18n.t("site.name"))
    assert_select "entry title", text: I18n.t("feed.entry_title", title: "Le Comte de Monte-Cristo", author: "Alexandre Dumas")
  end
end
