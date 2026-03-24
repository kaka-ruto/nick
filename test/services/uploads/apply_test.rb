require "test_helper"
require "zip"

class Uploads::ApplyTest < ActiveSupport::TestCase
  setup do
    @api_key, = ApiKey.issue!(user: users(:david), name: "uploads", scopes: [ "books:write", "books:publish" ])
  end

  test "applies zip upload by creating book pages sections and revision" do
    upload = create_upload_from_zip(build_zip_from_directory(Rails.root.join("books/chapterwan-manual")))

    assert_difference -> { Book.count }, +1 do
      assert_difference -> { BookUnit.count }, +4 do
        assert_difference -> { BookRevision.count }, +1 do
          Uploads::Apply.call(upload: upload, publish: true)
        end
      end
    end

    upload.reload
    assert_equal "accepted", upload.status
    assert_equal 1, upload.book.import_revision
    assert_equal [ "Page", "Page", "Page", "Section" ], upload.book.book_units.order(:position).map { |unit| unit.leaf.leafable_type }
    assert_equal [ "Welcome", "Writing in Markdown", "Publishing", "Appendix" ], upload.book.book_units.order(:position).map { |unit| unit.leaf.title }
    assert_equal upload.book.current_draft_revision_id, upload.book.published_revision_id
  end

  test "updates by external id and removes deleted units" do
    initial_zip = build_zip_from_hash(
      "book.yml" => <<~YML,
        title: Multi File
        category: General
      YML
      "content/001-intro.md" => "---\ntitle: Intro\nid: intro\n---\n# Intro\nOne",
      "content/010-notes.md" => "---\nclass: Section\ntitle: Notes\nid: notes\ntheme: dark\n---\nTwo"
    )

    upload = create_upload_from_zip(initial_zip)
    Uploads::Apply.call(upload: upload)

    updated_zip = build_zip_from_hash(
      "book.yml" => <<~YML,
        title: Multi File
        category: General
      YML
      "content/001-intro.md" => "---\ntitle: Intro\nid: intro\n---\n# Intro\nOne updated",
      "content/002-added.md" => "---\ntitle: Added\nid: added\n---\n# Added\nThree"
    )

    update_upload = create_upload_from_zip(updated_zip, book: upload.book, expected_revision: 1)
    Uploads::Apply.call(upload: update_upload)

    book = update_upload.reload.book
    assert_equal 2, book.import_revision
    assert_equal [ "intro", "added" ], book.book_units.order(:position).pluck(:external_id)
    assert_match "updated", book.book_units.find_by!(external_id: "intro").leaf.page.body.content.to_s
    assert_equal 2, book.book_revisions.count
  end

  test "fails on revision mismatch" do
    upload = create_upload_from_zip(build_zip_from_directory(Rails.root.join("books/chapterwan-manual")))
    Uploads::Apply.call(upload: upload)

    conflict = create_upload_from_zip(build_zip_from_directory(Rails.root.join("books/chapterwan-manual")), book: upload.book, expected_revision: 0)

    assert_raises StandardError do
      Uploads::Apply.call(upload: conflict)
    end

    assert_equal "failed", conflict.reload.status
    assert_match "revision mismatch", conflict.error_message
  end

  private
    def create_upload_from_zip(zip_data, book: nil, expected_revision: nil)
      parsed = Uploads::MarkdownParser.call(content: zip_data, filename: "bundle.zip")

      Upload.create!(
        api_key: @api_key,
        user: users(:david),
        book: book,
        expected_revision: expected_revision,
        source_sha256: Digest::SHA256.hexdigest(zip_data),
        parser_version: Upload::PARSER_VERSION,
        status: :processing,
        plan: { book: parsed.book_attributes, units: parsed.units }
      )
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
