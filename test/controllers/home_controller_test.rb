require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get home_url
    assert_response :redirect
  end

  test "renders for signed in users" do
    sign_in :david
    get home_url
    assert_response :success
    assert_select "h1", text: "Overview"
  end
end
