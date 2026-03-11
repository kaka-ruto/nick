require "test_helper"

class Api::BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:handbook)
    @write_key, @write_token = ApiKey.issue!(user: users(:david), name: "writer", scopes: [ "books:write" ])
    @publish_key, @publish_token = ApiKey.issue!(user: users(:david), name: "publisher", scopes: [ "books:publish" ])
  end

  test "requires bearer token" do
    post api_books_url, params: { book: { title: "No Auth" } }, as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body["error"]
  end

  test "requires idempotency key for writes" do
    post api_books_url,
      params: { book: { title: "No Key", theme: "blue" } },
      headers: auth_headers(@write_token),
      as: :json

    assert_response :unprocessable_entity
    assert_equal "idempotency_key_required", response.parsed_body["error"]
  end

  test "creates a book" do
    assert_difference -> { Book.count }, +1 do
      assert_difference -> { ApiKeyEvent.count }, +1 do
        post api_books_url,
          params: { book: { title: "Agent Book", subtitle: "Sub", author: "Bot", theme: "green", everyone_access: false } },
          headers: write_headers("create-book"),
          as: :json
      end
    end

    assert_response :created
    assert_equal "Agent Book", response.parsed_body.dig("book", "title")
    assert_equal "green", response.parsed_body.dig("book", "theme")
  end

  test "replays same idempotency key" do
    headers = write_headers("same-request")
    params = { book: { title: "Replayable", theme: "blue", everyone_access: false } }

    assert_difference -> { Book.count }, +1 do
      post api_books_url, params:, headers:, as: :json
    end
    first_body = response.body

    assert_no_difference -> { Book.count } do
      post api_books_url, params:, headers:, as: :json
    end

    assert_response :created
    assert_equal JSON.parse(first_body), response.parsed_body
  end

  test "rejects idempotency key reuse with different payload" do
    headers = write_headers("conflicting-request")

    @write_key.idempotency_keys.create!(
      key: "conflicting-request",
      request_fingerprint: "different",
      response_status: 201,
      response_body: { book: { id: 999 } }.to_json
    )

    assert_no_difference -> { Book.count } do
      post api_books_url, params: { book: { title: "Two", theme: "blue", everyone_access: false } }, headers:, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "updates pricing with write scope" do
    patch pricing_api_book_url(@book),
      params: { book: { pricing_type: "paid", price_cents: 3500 } },
      headers: write_headers("pricing"),
      as: :json

    assert_response :success
    assert_equal "paid", @book.reload.pricing_type
    assert_equal 3500, @book.price_cents
  end

  test "publishes with publish scope" do
    patch publication_api_book_url(@book),
      params: { book: { published: true } },
      headers: publish_headers("publish"),
      as: :json

    assert_response :success
    assert_predicate @book.reload, :published?
  end

  test "forbids publish when scope is missing" do
    patch publication_api_book_url(@book),
      params: { book: { published: true } },
      headers: write_headers("publish-forbidden"),
      as: :json

    assert_response :forbidden
    assert_equal "books:publish", response.parsed_body["required_scope"]
  end

  test "uploads a cover" do
    cover = file_fixture("white-rabbit.webp").open

    put cover_api_book_url(@book),
      params: { cover: Rack::Test::UploadedFile.new(cover.path, "image/webp") },
      headers: write_headers("cover"),
      as: :multipart

    assert_response :success
    assert_predicate @book.reload.cover, :attached?
  end

  test "upserts chapters and pages" do
    assert_difference -> { @book.reload.leaves.count }, +1 do
      post api_book_chapters_url(@book),
        params: { chapter: { body: "Intro", theme: "blue" }, leaf: { title: "Chapter 1" } },
        headers: write_headers("chapter-create"),
        as: :json
    end

    assert_response :created
    chapter_id = response.parsed_body.dig("chapter", "id")

    assert_no_difference -> { @book.reload.leaves.count } do
      post api_book_chapters_url(@book),
        params: { leaf_id: chapter_id, chapter: { body: "Intro updated", theme: "green" }, leaf: { title: "Chapter One" } },
        headers: write_headers("chapter-update"),
        as: :json
    end

    assert_response :success
    chapter = @book.reload.leaves.find(chapter_id)
    assert_equal "Chapter One", chapter.title
    assert_equal "Intro updated", chapter.leafable.body

    assert_difference -> { @book.reload.leaves.count }, +1 do
      post api_book_pages_url(@book),
        params: { page: { body: "# Hello" }, leaf: { title: "Page 1" } },
        headers: write_headers("page-create"),
        as: :json
    end

    assert_response :created
  end

  private
    def auth_headers(token)
      { "Authorization" => "Bearer #{token}" }
    end

    def write_headers(idempotency_key)
      auth_headers(@write_token).merge("Idempotency-Key" => idempotency_key)
    end

    def publish_headers(idempotency_key)
      auth_headers(@publish_token).merge("Idempotency-Key" => idempotency_key)
    end
end
