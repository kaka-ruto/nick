require "application_system_test_case"

class SellerOnboardingTest < ApplicationSystemTestCase
  setup do
    users(:kevin).update!(sell_paid_books: nil)
  end

  test "user can choose free-only mode from onboarding" do
    sign_in "kevin@37.local"
    assert_text "Do you want to sell paid books?"

    choose "No, keep my books free-only"
    click_button "Continue"

    assert_text "Overview"
    assert_equal false, users(:kevin).reload.sell_paid_books
  end

  test "user choosing paid mode is sent to billing" do
    sign_in "kevin@37.local"
    assert_text "Do you want to sell paid books?"

    choose "Yes, I want to sell paid books"
    click_button "Continue"

    assert_selector "h1", text: "Billing"
    assert_equal true, users(:kevin).reload.sell_paid_books
    assert_text "Seller payouts (Stripe Connect)"
  end
end
