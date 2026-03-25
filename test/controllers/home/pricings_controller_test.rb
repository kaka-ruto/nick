require "test_helper"

class Home::PricingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show renders" do
    get home_pricing_url
    assert_response :success
    assert_select "h1", text: "Pricing"
  end
end
