require "test_helper"

class Home::BillingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show renders" do
    get home_billing_url
    assert_response :success
    assert_select "h1", text: "Billing"
  end
end
