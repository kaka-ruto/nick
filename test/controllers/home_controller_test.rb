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

  test "renders seller action required card when flagged" do
    user = users(:david)
    user.update!(seller_attention_required: true, seller_attention_reason: "Pricing type cannot be paid until seller completes Stripe Connect onboarding")

    sign_in :david
    get home_url

    assert_response :success
    assert_select "p", text: "Action required"
    assert_select "h2", text: "Agent work needs a human unblock"
    assert_select "p", text: /Stripe Connect onboarding/
  end

  test "does not show seller action card by default" do
    sign_in :david
    get home_url

    assert_response :success
    assert_select "p", text: "Action required", count: 0
  end
end
