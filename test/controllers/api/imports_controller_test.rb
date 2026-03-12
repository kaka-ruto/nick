require "test_helper"

class Api::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @write_key, @write_token = ApiKey.issue!(user: users(:david), name: "ingest-write", scopes: [ "books:write" ])
    @full_key, @full_token = ApiKey.issue!(user: users(:david), name: "ingest-full", scopes: [ "books:write", "books:publish" ])
  end

  test "create import parses and stores plan" do
    assert_difference -> { Import.count }, +1 do
      post api_imports_url,
        params: { source_file: upload_fixture("import_book.md") },
        headers: headers(@write_token, "import-create"),
        as: :multipart
    end

    assert_response :created
    import = Import.last
    assert_equal "parsed", import.status
    assert import.source_file.attached?
    assert_equal "Ingestion Manual", import.plan.dig("book", "title")
    assert_equal 2, import.plan.fetch("units").size
  end

  test "create with apply persists book" do
    assert_difference -> { Book.count }, +1 do
      post api_imports_url,
        params: { source_file: upload_fixture("import_book.md"), apply: true },
        headers: headers(@full_token, "import-apply"),
        as: :multipart
    end

    assert_response :created
    assert_equal "applied", response.parsed_body.dig("import", "status")
    assert_equal 2, response.parsed_body.dig("import", "result", "units_count")
  end

  test "apply endpoint updates existing book by revision" do
    post api_imports_url,
      params: { source_file: upload_fixture("import_book.md"), apply: true },
      headers: headers(@full_token, "import-first"),
      as: :multipart

    book_id = response.parsed_body.dig("import", "book_id")

    post api_imports_url,
      params: { source_file: upload_fixture("import_book_update.md"), book_id: book_id, expected_revision: 1 },
      headers: headers(@write_token, "import-update"),
      as: :multipart

    import_id = response.parsed_body.dig("import", "id")

    post apply_api_import_url(import_id), headers: headers(@write_token, "import-update-apply"), as: :json

    assert_response :success
    book = Book.find(book_id)
    assert_equal 2, book.import_revision
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

      post api_imports_url,
        params: { source_file: Rack::Test::UploadedFile.new(file.path, "text/markdown"), apply: true },
        headers: headers(@write_token, "import-scope"),
        as: :multipart
    end

    assert_response :unprocessable_entity
    assert_equal "import_apply_failed", response.parsed_body["error"]
  end

  test "show returns import state" do
    post api_imports_url,
      params: { source_file: upload_fixture("import_book.md") },
      headers: headers(@write_token, "import-show"),
      as: :multipart

    import_id = response.parsed_body.dig("import", "id")

    get api_import_url(import_id), headers: headers(@write_token, "import-show-get"), as: :json

    assert_response :success
    assert_equal import_id, response.parsed_body.dig("import", "id")
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
