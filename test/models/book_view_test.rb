require "test_helper"

class BookViewTest < ActiveSupport::TestCase
  test "record deduplicates signed out visitor per day" do
    book = books(:handbook)

    assert_difference -> { BookView.count }, +1 do
      BookView.record!(book: book, user: nil, visitor_id: "anon-1", viewed_on: Date.current)
    end

    assert_no_difference -> { BookView.count } do
      BookView.record!(book: book, user: nil, visitor_id: "anon-1", viewed_on: Date.current)
    end
  end

  test "record deduplicates signed in user per day" do
    book = books(:handbook)
    user = users(:david)

    assert_difference -> { BookView.count }, +1 do
      BookView.record!(book: book, user: user, visitor_id: "anon-2", viewed_on: Date.current)
    end

    assert_no_difference -> { BookView.count } do
      BookView.record!(book: book, user: user, visitor_id: "anon-2", viewed_on: Date.current)
    end
  end
end
