require "application_system_test_case"

class PaidPublishGatingTest < ApplicationSystemTestCase
  setup do
    users(:david).update!(sell_paid_books: false)
    sign_in "kevin@37.local"
    assert_text "Overview"
  end

  test "editing to paid is allowed, but publishing stays blocked until seller setup is complete" do
    visit edit_book_url(books(:handbook))

    choose "book_pricing_type_paid"
    fill_in "book_price_cents", with: "1000"
    execute_script("document.getElementById('book-editor').requestSubmit()")

    assert_text "Handbook"
    assert_no_selector "#invite_url"

    check "book_published", allow_label_click: true

    assert_no_selector "#invite_url"
    assert_text "Publication link"
  end
end
