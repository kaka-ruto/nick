require "test_helper"

class Home::StripeConnectAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "create creates connect account and redirects to onboarding" do
    user = users(:david)
    user.update!(sell_paid_books: false)
    user.set_merchant_processor(:stripe, processor_id: "acct_123", onboarding_complete: false)
    retrieved = Struct.new(:details_submitted, :charges_enabled, :payouts_enabled).new(true, true, true)
    account_link = Struct.new(:url).new("https://example.com/onboarding")
    Stripe::Account.stubs(:retrieve).returns(retrieved)
    Stripe::AccountLink.stubs(:create).returns(account_link)
    post home_stripe_connect_account_url

    assert_redirected_to "https://example.com/onboarding"
    assert users(:david).reload.merchant_processor.onboarding_complete?
    assert_equal true, users(:david).reload.sell_paid_books
  end

  test "sync refreshes connect status and returns to billing" do
    user = users(:david)
    user.update!(sell_paid_books: false)
    user.set_merchant_processor(:stripe, processor_id: "acct_123", onboarding_complete: false)

    retrieved = Struct.new(:details_submitted, :charges_enabled, :payouts_enabled).new(true, true, true)
    Stripe::Account.stubs(:retrieve).returns(retrieved)
    post sync_home_stripe_connect_account_url

    assert_redirected_to home_billing_url
    assert user.reload.stripe_connect_ready?
    assert_equal true, user.reload.sell_paid_books
  end
end
