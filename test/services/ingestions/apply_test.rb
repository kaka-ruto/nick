require "test_helper"

class Ingestions::ApplyTest < ActiveSupport::TestCase
  setup do
    @api_key, = ApiKey.issue!(user: users(:david), name: "ingest", scopes: [ "books:write", "books:publish" ])
  end

  test "applies ingestion by creating book and units" do
    ingestion = create_ingestion_from_fixture("ingestion_book.md")

    assert_difference -> { Book.count }, +1 do
      assert_difference -> { BookUnit.count }, +2 do
        Ingestions::Apply.call(ingestion: ingestion)
      end
    end

    ingestion.reload
    assert_equal "applied", ingestion.status
    assert_equal 1, ingestion.book.ingestion_revision
    assert_equal [ "Welcome", "Setup" ], ingestion.book.book_units.order(:position).map { |unit| unit.leaf.title }
  end

  test "updates existing units and removes deleted units" do
    original = create_ingestion_from_fixture("ingestion_book.md")
    Ingestions::Apply.call(ingestion: original)

    update_ingestion = create_ingestion_from_fixture("ingestion_book_update.md", book: original.book, expected_revision: 1)

    assert_no_difference -> { Book.count } do
      Ingestions::Apply.call(ingestion: update_ingestion)
    end

    book = update_ingestion.reload.book
    assert_equal 2, book.book_units.count
    assert_equal 2, book.ingestion_revision
    assert_equal [ "Welcome", "New Section" ], book.book_units.order(:position).map { |unit| unit.leaf.title }
    assert_match "updated welcome page", book.book_units.order(:position).first.leaf.page.body.content.to_s
  end

  test "fails on revision mismatch" do
    ingestion = create_ingestion_from_fixture("ingestion_book.md")
    Ingestions::Apply.call(ingestion: ingestion)

    conflict = create_ingestion_from_fixture("ingestion_book_update.md", book: ingestion.book, expected_revision: 0)

    assert_raises StandardError do
      Ingestions::Apply.call(ingestion: conflict)
    end

    assert_equal "failed", conflict.reload.status
    assert_match "revision mismatch", conflict.error_message
  end

  private
    def create_ingestion_from_fixture(name, book: nil, expected_revision: nil)
      content = file_fixture(name).read
      parsed = Ingestions::MarkdownParser.call(content: content)

      BookIngestion.create!(
        api_key: @api_key,
        user: users(:david),
        book: book,
        expected_revision: expected_revision,
        source_sha256: Digest::SHA256.hexdigest(content),
        parser_version: BookIngestion::PARSER_VERSION,
        status: :parsed,
        plan: { book: parsed.book_attributes, units: parsed.units }
      )
    end
end
