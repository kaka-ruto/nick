require "test_helper"

class Ingestions::MarkdownParserTest < ActiveSupport::TestCase
  test "parses front matter and heading units" do
    markdown = file_fixture("ingestion_book.md").read

    result = Ingestions::MarkdownParser.call(content: markdown)

    assert_equal "Ingestion Manual", result.book_attributes[:title]
    assert_equal "Engineering", result.book_attributes[:category_name]
    assert_equal [ "ingest", "automation" ], result.book_attributes[:tag_names]

    assert_equal 2, result.units.size
    assert_equal "001-welcome", result.units.first[:external_id]
    assert_equal "Welcome", result.units.first[:title]
    assert_match "welcome page", result.units.first[:body]
  end

  test "uses fallback unit when no top heading exists" do
    result = Ingestions::MarkdownParser.call(content: "Just body")

    assert_equal 1, result.units.size
    assert_equal "Untitled", result.units.first[:title]
  end
end
