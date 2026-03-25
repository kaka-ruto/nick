require "test_helper"

class Home::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show renders" do
    get home_settings_url
    assert_response :success
    assert_select "h1", text: "Settings"
  end
end
