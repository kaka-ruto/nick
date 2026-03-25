require "test_helper"

class Home::BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "index renders" do
    get home_books_url
    assert_response :success
    assert_select "h1", text: "Books"
  end

  test "show renders for accessible book" do
    get home_book_url(books(:handbook))
    assert_response :success
    assert_select "h1", text: "Handbook"
  end
end
