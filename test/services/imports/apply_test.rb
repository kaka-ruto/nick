require "test_helper"

class Imports::ApplyTest < ActiveSupport::TestCase
  setup do
    @api_key, = ApiKey.issue!(user: users(:david), name: "ingest", scopes: [ "books:write", "books:publish" ])
  end

  test "applies import by creating book and units" do
    import = create_import_from_fixture("import_book.md")

    assert_difference -> { Book.count }, +1 do
      assert_difference -> { BookUnit.count }, +2 do
        Imports::Apply.call(import: import)
      end
    end

    import.reload
    assert_equal "applied", import.status
    assert_equal 1, import.book.import_revision
    assert_equal [ "Welcome", "Setup" ], import.book.book_units.order(:position).map { |unit| unit.leaf.title }
  end

  test "updates existing units and removes deleted units" do
    original = create_import_from_fixture("import_book.md")
    Imports::Apply.call(import: original)

    update_import = create_import_from_fixture("import_book_update.md", book: original.book, expected_revision: 1)

    assert_no_difference -> { Book.count } do
      Imports::Apply.call(import: update_import)
    end

    book = update_import.reload.book
    assert_equal 2, book.book_units.count
    assert_equal 2, book.import_revision
    assert_equal [ "Welcome", "New Section" ], book.book_units.order(:position).map { |unit| unit.leaf.title }
    assert_match "updated welcome page", book.book_units.order(:position).first.leaf.page.body.content.to_s
  end

  test "fails on revision mismatch" do
    import = create_import_from_fixture("import_book.md")
    Imports::Apply.call(import: import)

    conflict = create_import_from_fixture("import_book_update.md", book: import.book, expected_revision: 0)

    assert_raises StandardError do
      Imports::Apply.call(import: conflict)
    end

    assert_equal "failed", conflict.reload.status
    assert_match "revision mismatch", conflict.error_message
  end

  private
    def create_import_from_fixture(name, book: nil, expected_revision: nil)
      content = file_fixture(name).read
      parsed = Imports::MarkdownParser.call(content: content)

      Import.create!(
        api_key: @api_key,
        user: users(:david),
        book: book,
        expected_revision: expected_revision,
        source_sha256: Digest::SHA256.hexdigest(content),
        parser_version: Import::PARSER_VERSION,
        status: :parsed,
        plan: { book: parsed.book_attributes, units: parsed.units }
      )
    end
end
