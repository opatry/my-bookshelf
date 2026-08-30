require "test_helper"

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  test "index lists tags" do
    get admin_tags_path

    assert_response :success
    assert_select "table tbody tr", count: Tag.count
  end

  test "creates a tag with an auto slug" do
    assert_difference -> { Tag.count } => 1 do
      post admin_tags_path, params: { tag: { name: "Fantastique" } }
    end

    tag = Tag.find_by(name: "Fantastique")
    assert_equal "fantastique", tag.slug
    assert_redirected_to admin_tags_path
  end

  test "rejects a duplicate tag" do
    assert_no_difference -> { Tag.count } do
      post admin_tags_path, params: { tag: { name: "Thriller" } }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
  end

  test "updates a tag" do
    tag = tags(:one)

    patch admin_tag_path(tag), params: { tag: { name: "Polar" } }

    assert_redirected_to admin_tags_path
    assert_equal "Polar", tag.reload.name
    assert_equal "polar", tag.reload.slug
  end

  test "destroys a tag" do
    tag = Tag.create!(name: "Orphelin")

    assert_difference -> { Tag.count } => -1 do
      delete admin_tag_path(tag)
    end

    assert_redirected_to admin_tags_path
  end
end
