require "test_helper"

class Home::PublishingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show renders" do
    get home_publishing_url
    assert_response :success
    assert_select "h1", text: "Publishing"
  end
end
