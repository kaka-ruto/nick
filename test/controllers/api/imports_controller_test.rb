require "test_helper"
require "zip"

class Api::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @write_key, @write_token = ApiKey.issue!(user: users(:david), name: "imports-write", scopes: [ "books:write" ])
    @full_key, @full_token = ApiKey.issue!(user: users(:david), name: "imports-full", scopes: [ "books:write", "books:publish" ])
  end

  test "create import parses zip bundle and stores plan" do
    assert_difference -> { Import.count }, +1 do
      post api_imports_url,
        params: { source_file: bundled_upload },
        headers: headers(@write_token, "import-create"),
        as: :multipart
    end

    assert_response :created
    import = Import.last
    assert_equal "parsed", import.status
    assert import.source_file.attached?
    assert_equal "The Chapterwan Manual", import.plan.dig("book", "title")
    assert_equal 4, import.plan.fetch("units").size
    assert_equal "section", import.plan.fetch("units").last.fetch("kind")
  end

  test "create with apply builds book and units" do
    assert_difference -> { Book.count }, +1 do
      post api_imports_url,
        params: { source_file: bundled_upload, apply: true },
        headers: headers(@full_token, "import-apply"),
        as: :multipart
    end

    assert_response :created
    assert_equal "applied", response.parsed_body.dig("import", "status")
    assert_equal 4, response.parsed_body.dig("import", "result", "units_count")
  end

  test "apply endpoint updates existing book by revision" do
    post api_imports_url,
      params: { source_file: bundled_upload, apply: true },
      headers: headers(@full_token, "import-first"),
      as: :multipart

    book_id = response.parsed_body.dig("import", "book_id")

    post api_imports_url,
      params: { source_file: updated_bundle_upload, book_id: book_id, expected_revision: 1 },
      headers: headers(@write_token, "import-update"),
      as: :multipart

    import_id = response.parsed_body.dig("import", "id")

    post apply_api_import_url(import_id), headers: headers(@write_token, "import-update-apply"), as: :json

    assert_response :success
    book = Book.find(book_id)
    assert_equal 2, book.import_revision
    assert_equal [ "welcome", "writing-markdown", "appendix", "new-page" ], book.book_units.order(:position).pluck(:external_id)
  end

  test "apply with published true needs publish scope" do
    zip_data = build_zip_from_hash(
      "book.yml" => "title: Scoped Publish\ncategory: General\npublished: true\nfiles:\n  - path: content/01.md\n",
      "content/01.md" => "---\ntitle: Intro\n---\nBody"
    )

    post api_imports_url,
      params: { source_file: upload_zip_data(zip_data), apply: true },
      headers: headers(@write_token, "import-scope"),
      as: :multipart

    assert_response :unprocessable_entity
    assert_equal "import_apply_failed", response.parsed_body["error"]
  end

  test "show returns import state" do
    post api_imports_url,
      params: { source_file: bundled_upload },
      headers: headers(@write_token, "import-show"),
      as: :multipart

    import_id = response.parsed_body.dig("import", "id")

    get api_import_url(import_id), headers: headers(@write_token, "import-show-get"), as: :json

    assert_response :success
    assert_equal import_id, response.parsed_body.dig("import", "id")
  end

  private
    def bundled_upload
      upload_zip_data(build_zip_from_directory(Rails.root.join("books/the-chapterwan-manual")))
    end

    def updated_bundle_upload
      zip_data = build_zip_from_hash(
        "book.yml" => <<~YML,
          title: The Chapterwan Manual
          subtitle: How to use Chapterwan
          author: Chapterwan Team
          category: General
          tags:
            - manual
            - publishing
            - onboarding
          pricing_type: free
          published: false
          files:
            - path: content/01-welcome.md
              kind: page
            - path: content/02-writing.md
              kind: page
            - path: content/04-appendix.md
              kind: section
            - path: content/05-new.md
              kind: page
        YML
        "content/01-welcome.md" => "---\ntitle: Welcome\nid: welcome\n---\n# Welcome\nUpdated",
        "content/02-writing.md" => "---\ntitle: Writing in Markdown\nid: writing-markdown\n---\n# Writing in Markdown\nStill here",
        "content/04-appendix.md" => "---\nclass: Section\ntitle: Appendix\nid: appendix\ntheme: dark\n---\nReference material",
        "content/05-new.md" => "---\ntitle: New Page\nid: new-page\n---\n# New Page\nBrand new"
      )

      upload_zip_data(zip_data)
    end

    def upload_zip_data(zip_data)
      file = Tempfile.new(["book", ".zip"])
      file.binmode
      file.write(zip_data)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "application/zip")
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

    def headers(token, idempotency_key)
      {
        "Authorization" => "Bearer #{token}",
        "Idempotency-Key" => idempotency_key
      }
    end
end
