require "test_helper"
require "zip"

class Imports::ApplyTest < ActiveSupport::TestCase
  setup do
    @api_key, = ApiKey.issue!(user: users(:david), name: "imports", scopes: [ "books:write", "books:publish" ])
  end

  test "applies zip import by creating book pages and sections" do
    import = create_import_from_zip(build_zip_from_directory(Rails.root.join("books/the-chapterwan-manual")))

    assert_difference -> { Book.count }, +1 do
      assert_difference -> { BookUnit.count }, +4 do
        Imports::Apply.call(import: import)
      end
    end

    import.reload
    assert_equal "applied", import.status
    assert_equal 1, import.book.import_revision
    assert_equal [ "Page", "Page", "Page", "Section" ], import.book.book_units.order(:position).map { |unit| unit.leaf.leafable_type }
    assert_equal [ "Welcome", "Writing in Markdown", "Publishing", "Appendix" ], import.book.book_units.order(:position).map { |unit| unit.leaf.title }
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

    import = create_import_from_zip(initial_zip)
    Imports::Apply.call(import: import)

    updated_zip = build_zip_from_hash(
      "book.yml" => <<~YML,
        title: Multi File
        category: General
      YML
      "content/001-intro.md" => "---\ntitle: Intro\nid: intro\n---\n# Intro\nOne updated",
      "content/002-added.md" => "---\ntitle: Added\nid: added\n---\n# Added\nThree"
    )

    update_import = create_import_from_zip(updated_zip, book: import.book, expected_revision: 1)
    Imports::Apply.call(import: update_import)

    book = update_import.reload.book
    assert_equal 2, book.import_revision
    assert_equal [ "intro", "added" ], book.book_units.order(:position).pluck(:external_id)
    assert_match "updated", book.book_units.find_by!(external_id: "intro").leaf.page.body.content.to_s
  end

  test "fails on revision mismatch" do
    import = create_import_from_zip(build_zip_from_directory(Rails.root.join("books/the-chapterwan-manual")))
    Imports::Apply.call(import: import)

    conflict = create_import_from_zip(build_zip_from_directory(Rails.root.join("books/the-chapterwan-manual")), book: import.book, expected_revision: 0)

    assert_raises StandardError do
      Imports::Apply.call(import: conflict)
    end

    assert_equal "failed", conflict.reload.status
    assert_match "revision mismatch", conflict.error_message
  end

  private
    def create_import_from_zip(zip_data, book: nil, expected_revision: nil)
      parsed = Imports::MarkdownParser.call(content: zip_data, filename: "bundle.zip")

      Import.create!(
        api_key: @api_key,
        user: users(:david),
        book: book,
        expected_revision: expected_revision,
        source_sha256: Digest::SHA256.hexdigest(zip_data),
        parser_version: Import::PARSER_VERSION,
        status: :parsed,
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
