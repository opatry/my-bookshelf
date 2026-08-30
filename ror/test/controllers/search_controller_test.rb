require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "returns matching books as JSON" do
    get search_path(q: "comte"), as: :json

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload.fetch("results").size
    result = payload["results"].first
    assert_equal "Le Comte de Monte-Cristo", result["title"]
    assert_equal "Alexandre Dumas", result["author"]
    assert_includes result["tags"], "Thriller"
    assert_match %r{\A/books/\d+-}, result["url"]
  end

  test "returns an empty list for short queries" do
    get search_path(q: "a"), as: :json

    assert_response :success
    assert_equal [], JSON.parse(response.body).fetch("results")
  end

  test "ignores other users books" do
    get search_path(q: "petit"), as: :json

    assert_response :success
    assert_equal [], JSON.parse(response.body).fetch("results")
  end
end
