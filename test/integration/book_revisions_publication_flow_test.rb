require "test_helper"

class BookRevisionsPublicationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:handbook)
    @write_key, @write_token = ApiKey.issue!(user: users(:david), name: "revision-writer", scopes: [ "books:write" ])
    @publish_key, @publish_token = ApiKey.issue!(user: users(:david), name: "revision-publisher", scopes: [ "books:publish" ])
  end

  test "publishes an older revision by re-projecting units and supports unpublish" do
    first_upload = create_upload
    second_upload = create_upload

    first_units = [
      {
        external_id: "welcome",
        kind: "page",
        title: "Welcome V1",
        body: "# Welcome\nVersion one",
        theme: nil,
        content_sha256: Digest::SHA256.hexdigest("v1")
      }
    ]
    second_units = [
      {
        external_id: "welcome",
        kind: "page",
        title: "Welcome V2",
        body: "# Welcome\nVersion two",
        theme: nil,
        content_sha256: Digest::SHA256.hexdigest("v2")
      }
    ]

    first_revision = BookRevision.create!(book: @book, upload: first_upload, number: 1, source_sha256: first_upload.source_sha256, metadata: {}, units: first_units)
    second_revision = BookRevision.create!(book: @book, upload: second_upload, number: 2, source_sha256: second_upload.source_sha256, metadata: {}, units: second_units)
    @book.update!(current_draft_revision: second_revision)
    Uploads::ProjectUnits.call(book: @book, units: second_units)

    post publish_api_book_url(@book),
      params: { revision_id: first_revision.id },
      headers: publish_headers("publish-revision"),
      as: :json

    assert_response :success
    @book.reload
    assert_equal first_revision.id, @book.published_revision_id
    assert_predicate @book, :published?
    assert_equal "Version one", @book.book_units.find_by!(external_id: "welcome").leaf.page.body.content.to_s.lines.last.strip

    post unpublish_api_book_url(@book), headers: publish_headers("unpublish-revision"), as: :json

    assert_response :success
    @book.reload
    assert_nil @book.published_revision_id
    assert_not @book.published?
  end

  private
    def create_upload
      Upload.create!(
        api_key: @write_key,
        user: users(:david),
        book: @book,
        source_sha256: SecureRandom.hex(32),
        parser_version: Upload::PARSER_VERSION,
        status: :accepted
      )
    end

    def publish_headers(idempotency_key)
      { "Authorization" => "Bearer #{@publish_token}", "Idempotency-Key" => idempotency_key }
    end
end
