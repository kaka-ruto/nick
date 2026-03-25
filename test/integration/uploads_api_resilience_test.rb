require "test_helper"
require "zip"

class UploadsApiResilienceTest < ActionDispatch::IntegrationTest
  setup do
    @writer_key, @writer_token = ApiKey.issue!(user: users(:david), name: "uploads-writer", scopes: [ "books:write" ])
    @publisher_key, @publisher_token = ApiKey.issue!(user: users(:david), name: "uploads-publisher", scopes: [ "books:write", "books:publish" ])
    @other_writer_key, @other_writer_token = ApiKey.issue!(user: users(:kevin), name: "other-writer", scopes: [ "books:write" ])
  end

  test "replays upload response for same idempotency key and payload" do
    zip_data = build_zip_from_directory(SourceBooks.cafaye_manual_dir)

    assert_difference -> { Upload.count }, +1 do
      post api_uploads_url,
        params: multipart_params(zip_data:, publish: false),
        headers: auth_headers(@writer_token, "upload-replay"),
        as: :multipart
    end

    assert_response :created
    first_body = response.parsed_body

    assert_no_difference -> { Upload.count } do
      post api_uploads_url,
        params: multipart_params(zip_data:, publish: false),
        headers: auth_headers(@writer_token, "upload-replay"),
        as: :multipart
    end

    assert_response :created
    assert_equal first_body, response.parsed_body
  end

  test "fails invalid bundle with structured validation errors" do
    invalid_zip = build_zip_from_hash(
      "book.yml" => <<~YML,
        schema_version: 1
        book_uid: broken-manual
        title: Broken Manual
        author: Broken Agent
      YML
      "content/001.md" => "---\nid: first\n---\nBroken"
    )

    assert_difference -> { Upload.count }, +1 do
      post api_uploads_url,
        params: multipart_params(zip_data: invalid_zip, publish: false),
        headers: auth_headers(@writer_token, "invalid-bundle"),
        as: :multipart
    end

    assert_response :unprocessable_entity
    upload = Upload.order(:id).last
    assert_equal "failed", upload.status
    assert_match "book.yml missing required fields", upload.error_message
    assert_equal [ upload.error_message ], upload.validation_errors
  end

  test "requires books publish scope for upload and publish" do
    zip_data = build_zip_from_directory(SourceBooks.cafaye_manual_dir)

    post api_uploads_url,
      params: multipart_params(zip_data:, publish: true),
      headers: auth_headers(@writer_token, "publish-scope-required"),
      as: :multipart

    assert_response :unprocessable_entity
    assert_match "books:publish scope required", response.parsed_body.fetch("detail")
  end

  test "rejects stale base revision updates and keeps only first accepted" do
    base_zip = build_zip_from_directory(SourceBooks.cafaye_manual_dir)
    first_upload_payload = create_upload(zip_data: base_zip, token: @writer_token, key: "seed-upload")
    book_id = first_upload_payload.fetch("upload").fetch("book_id")
    book = Book.find(book_id)
    assert_equal 1, book.import_revision

    update_a = build_zip_from_hash(
      "book.yml" => <<~YML,
        schema_version: 1
        book_uid: cafaye-manual
        title: The Cafaye Manual
        author: Cafaye Team
        reading_order:
          - content/001-welcome.md
      YML
      "content/001-welcome.md" => "---\ntitle: Welcome\nid: welcome\n---\n# Welcome\nA"
    )
    update_b = build_zip_from_hash(
      "book.yml" => <<~YML,
        schema_version: 1
        book_uid: cafaye-manual
        title: The Cafaye Manual
        author: Cafaye Team
        reading_order:
          - content/001-welcome.md
      YML
      "content/001-welcome.md" => "---\ntitle: Welcome\nid: welcome\n---\n# Welcome\nB"
    )

    accepted = create_upload(zip_data: update_a, token: @writer_token, key: "stale-a", book_id:, base_revision_id: 1)
    assert_equal "accepted", accepted.fetch("upload").fetch("status")

    stale = create_upload(zip_data: update_b, token: @writer_token, key: "stale-b", book_id:, base_revision_id: 1, expected_status: :unprocessable_entity)
    assert_equal "upload_failed", stale.fetch("error")
    assert_match "revision mismatch", stale.fetch("detail")

    book.reload
    assert_equal 2, book.import_revision
  end

  test "forbids revision and source access for writer without book access" do
    zip_data = build_zip_from_directory(SourceBooks.cafaye_manual_dir)
    upload_payload = create_upload(zip_data:, token: @writer_token, key: "access-seed")
    book_id = upload_payload.fetch("upload").fetch("book_id")
    revision_id = Book.find(book_id).book_revisions.order(number: :desc).first.id

    get api_book_revisions_url(book_id), headers: auth_headers(@other_writer_token, "other-revisions")
    assert_response :forbidden

    get source_api_book_url(book_id), headers: auth_headers(@other_writer_token, "other-source")
    assert_response :forbidden

    get "/api/books/#{book_id}/revisions/#{revision_id}/source", headers: auth_headers(@other_writer_token, "other-revision-source")
    assert_response :forbidden
  end

  private
    def create_upload(zip_data:, token:, key:, book_id: nil, base_revision_id: nil, expected_status: :created)
      post api_uploads_url,
        params: multipart_params(zip_data:, publish: false, book_id:, base_revision_id:),
        headers: auth_headers(token, key),
        as: :multipart

      assert_response expected_status
      response.parsed_body
    end

    def multipart_params(zip_data:, publish:, book_id: nil, base_revision_id: nil)
      {
        publish: publish,
        book_id: book_id,
        base_revision_id: base_revision_id,
        source_bundle: upload_fixture(zip_data)
      }.compact
    end

    def upload_fixture(zip_data)
      file = Tempfile.new([ "bundle", ".zip" ])
      file.binmode
      file.write(zip_data)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "application/zip", true, original_filename: "bundle.zip")
    end

    def auth_headers(token, idempotency_key)
      { "Authorization" => "Bearer #{token}", "Idempotency-Key" => idempotency_key }
    end

    def build_zip_from_directory(path)
      io = StringIO.new
      Zip::OutputStream.write_buffer(io) do |zip|
        Dir.glob(path.join("**/*")).sort.each do |file|
          next if File.directory?(file)

          relative = Pathname(file).relative_path_from(path).to_s
          zip.put_next_entry(relative)
          zip.write(File.binread(file))
        end
      end
      io.string
    end

    def build_zip_from_hash(entries)
      io = StringIO.new
      Zip::OutputStream.write_buffer(io) do |zip|
        entries.each do |path, content|
          zip.put_next_entry(path)
          zip.write(content)
        end
      end
      io.string
    end
end
