require "test_helper"

class Api::BookIngestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @write_key, @write_token = ApiKey.issue!(user: users(:david), name: "ingest-write", scopes: [ "books:write" ])
    @full_key, @full_token = ApiKey.issue!(user: users(:david), name: "ingest-full", scopes: [ "books:write", "books:publish" ])
  end

  test "create ingestion parses and stores plan" do
    assert_difference -> { BookIngestion.count }, +1 do
      post api_book_ingestions_url,
        params: { source_file: upload_fixture("ingestion_book.md") },
        headers: headers(@write_token, "ingestion-create"),
        as: :multipart
    end

    assert_response :created
    ingestion = BookIngestion.last
    assert_equal "parsed", ingestion.status
    assert ingestion.source_file.attached?
    assert_equal "Ingestion Manual", ingestion.plan.dig("book", "title")
    assert_equal 2, ingestion.plan.fetch("units").size
  end

  test "create with apply persists book" do
    assert_difference -> { Book.count }, +1 do
      post api_book_ingestions_url,
        params: { source_file: upload_fixture("ingestion_book.md"), apply: true },
        headers: headers(@full_token, "ingestion-apply"),
        as: :multipart
    end

    assert_response :created
    assert_equal "applied", response.parsed_body.dig("ingestion", "status")
    assert_equal 2, response.parsed_body.dig("ingestion", "result", "units_count")
  end

  test "apply endpoint updates existing book by revision" do
    post api_book_ingestions_url,
      params: { source_file: upload_fixture("ingestion_book.md"), apply: true },
      headers: headers(@full_token, "ingestion-first"),
      as: :multipart

    book_id = response.parsed_body.dig("ingestion", "book_id")

    post api_book_ingestions_url,
      params: { source_file: upload_fixture("ingestion_book_update.md"), book_id: book_id, expected_revision: 1 },
      headers: headers(@write_token, "ingestion-update"),
      as: :multipart

    ingestion_id = response.parsed_body.dig("ingestion", "id")

    post apply_api_book_ingestion_url(ingestion_id), headers: headers(@write_token, "ingestion-update-apply"), as: :json

    assert_response :success
    book = Book.find(book_id)
    assert_equal 2, book.ingestion_revision
    assert_equal [ "Welcome", "New Section" ], book.book_units.order(:position).map { |unit| unit.leaf.title }
  end

  test "apply with published true needs publish scope" do
    content = <<~MD
      ---
      title: Scoped Publish
      category: General
      published: true
      ---

      # Intro

      Body
    MD

    Tempfile.create(["scoped", ".md"]) do |file|
      file.write(content)
      file.rewind

      post api_book_ingestions_url,
        params: { source_file: Rack::Test::UploadedFile.new(file.path, "text/markdown"), apply: true },
        headers: headers(@write_token, "ingestion-scope"),
        as: :multipart
    end

    assert_response :unprocessable_entity
    assert_equal "ingestion_apply_failed", response.parsed_body["error"]
  end

  test "show returns ingestion state" do
    post api_book_ingestions_url,
      params: { source_file: upload_fixture("ingestion_book.md") },
      headers: headers(@write_token, "ingestion-show"),
      as: :multipart

    ingestion_id = response.parsed_body.dig("ingestion", "id")

    get api_book_ingestion_url(ingestion_id), headers: headers(@write_token, "ingestion-show-get"), as: :json

    assert_response :success
    assert_equal ingestion_id, response.parsed_body.dig("ingestion", "id")
  end

  private
    def upload_fixture(name)
      Rack::Test::UploadedFile.new(file_fixture(name), "text/markdown")
    end

    def headers(token, idempotency_key)
      {
        "Authorization" => "Bearer #{token}",
        "Idempotency-Key" => idempotency_key
      }
    end
end
