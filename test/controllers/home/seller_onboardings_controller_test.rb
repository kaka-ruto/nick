require "test_helper"

class Home::SellerOnboardingsControllerTest < ActionDispatch::IntegrationTest
  test "show renders for signed in user" do
    sign_in :david
    users(:david).update!(sell_paid_books: nil)

    get home_seller_onboarding_url
    assert_response :success
    assert_select "h1", text: "Do you want to sell paid books?"
  end

  test "update to free only redirects home" do
    sign_in :david
    users(:david).update!(sell_paid_books: nil)

    patch home_seller_onboarding_url, params: { user: { sell_paid_books: false } }

    assert_redirected_to home_url
    assert_equal false, users(:david).reload.sell_paid_books
  end

  test "update to sell paid books redirects billing" do
    sign_in :david
    users(:david).update!(sell_paid_books: nil)

    patch home_seller_onboarding_url, params: { user: { sell_paid_books: true } }

    assert_redirected_to home_billing_url
    assert_equal true, users(:david).reload.sell_paid_books
  end
end
