require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  test "tag cloud lists owned tags with counts" do
    get tags_path

    assert_response :success
    assert_select ".tag-cloud a", text: "Thriller"
    assert_select ".tag-count", text: "(1)"
  end

  test "shows the books tagged by the owner" do
    tag = tags(:one)

    get tag_path(tag)

    assert_response :success
    assert_select "h1", text: /#{Regexp.escape(tag.name)}/
    assert_select ".book-title", text: "Le Comte de Monte-Cristo"
  end

  test "404 for an unknown tag slug" do
    get "/tags/inexistant"

    assert_response :not_found
  end
end
