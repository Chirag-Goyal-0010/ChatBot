require "test_helper"

class WebsitesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get websites_new_url
    assert_response :success
  end

  test "should get create" do
    get websites_create_url
    assert_response :success
  end

  test "should get index" do
    get websites_index_url
    assert_response :success
  end
end
