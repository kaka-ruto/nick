require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "index lists the current user's books" do
    get root_url

    assert_redirected_to home_url
  end

  test "library includes published books even when the user does not have access" do
    books(:manual).update!(published: true)

    get library_url

    assert_response :success
    assert_select "h3", text: "Manual"
  end

  test "library filters by category" do
    books(:manual).update!(published: true)

    get library_url, params: { category_id: categories(:engineering).id }

    assert_response :success
    assert_select "h3", text: "Manual"
    assert_select "h3", text: "Handbook", count: 0
  end

  test "index shows signed out homepage with published highlights when not logged in" do
    books(:manual).update!(published: true)

    sign_out
    get root_url

    assert_response :success
    assert_select "h1", text: /Turn your ideas into published books, faster./
    assert_select "h4", text: "Manual"
  end

  test "index is publicly accessible when not signed in and no published books exist" do
    sign_out
    get root_url

    assert_response :success
  end

  test "create makes the current user an editor" do
    assert_difference -> { Book.count }, +1 do
      post books_url, params: { book: { title: "New Book", everyone_access: false } }
    end

    assert_redirected_to book_slug_url(Book.last)

    book = Book.last
    assert_equal "New Book", book.title
    assert_equal 1, Book.last.accesses.count
    assert_equal users(:kevin), book.seller_user

    assert book.editable?(user: users(:kevin))
  end

  test "create sets additional accesses" do
    sign_in :jason
    assert_difference -> { Book.count }, +1 do
      post books_url, params: { book: { title: "New Book", everyone_access: false }, "editor_ids[]": users(:jz).id, "reader_ids[]": users(:kevin).id }
    end

    book = Book.last
    assert_equal "New Book", book.title
    assert_equal 3, Book.last.accesses.count

    assert book.editable?(user: users(:jz))

    assert book.accessable?(user: users(:kevin))
    assert_not book.editable?(user: users(:kevin))
  end

  test "create allows paid draft when seller setup is incomplete" do
    assert_difference -> { Book.count }, +1 do
      post books_url, params: { book: { title: "Paid Draft", everyone_access: false, pricing_type: "paid", price_cents: 1200, price_currency: "USD" } }
    end

    book = Book.last
    assert_redirected_to book_slug_url(book)
    assert_equal "paid", book.pricing_type
    assert_not book.published?
  end

  test "show only shows books the current user can access" do
    get book_slug_url(books(:manual))
    assert_response :not_found

    get book_slug_url(books(:handbook))
    assert_response :success
  end

  test "show includes OG metadata for public access" do
    get book_slug_url(books(:handbook))
    assert_response :success

    assert_select "meta[property='og:title'][content='Handbook']"
    assert_select "meta[property='og:url'][content='#{book_slug_url(books(:handbook))}']"
  end

  test "show records one view for signed out visitor" do
    books(:handbook).update!(published: true)
    sign_out

    assert_difference -> { BookView.count }, +1 do
      get book_slug_url(books(:handbook))
    end

    assert_no_difference -> { BookView.count } do
      get book_slug_url(books(:handbook))
    end
  end
end
