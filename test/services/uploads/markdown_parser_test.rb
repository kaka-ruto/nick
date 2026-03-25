require "test_helper"
require "zip"

class Uploads::MarkdownParserTest < ActiveSupport::TestCase
  test "parses single markdown file using front matter" do
    markdown = <<~MD
      ---
      title: Single File
      id: single-file
      class: Section
      theme: dark
      category: Engineering
      tags:
        - single
      ---
      Body
    MD

    result = Uploads::MarkdownParser.call(content: markdown, filename: "single.md")

    assert_equal "Single File", result.book_attributes[:title]
    assert_equal "Engineering", result.book_attributes[:category_name]
    assert_equal [ "single" ], result.book_attributes[:tag_names]

    assert_equal 1, result.units.size
    unit = result.units.first
    assert_equal "section", unit[:kind]
    assert_equal "Single File", unit[:title]
    assert_equal "dark", unit[:theme]
  end

  test "requires explicit reading_order in bundle manifest" do
    zip_data = build_zip_from_hash(
      "book.yml" => <<~YML,
        schema_version: 1
        book_uid: manual
        title: Manual
        author: Agent
      YML
      "content/001.md" => "---\ntitle: Intro\nid: intro\n---\nOne"
    )

    error = assert_raises(ArgumentError) do
      Uploads::MarkdownParser.call(content: zip_data, filename: "manual.zip")
    end

    assert_match "book.yml missing required fields", error.message
  end

  test "parses zip bundle with manifest ordering and kinds" do
    zip_data = build_zip_from_directory(Rails.root.join("books/chapterwan-manual"))

    result = Uploads::MarkdownParser.call(content: zip_data, filename: "chapterwan-manual.zip")

    assert_equal "Chapterwan Manual", result.book_attributes[:title]
    assert_equal "General", result.book_attributes[:category_name]
    assert_equal [ "manual", "publishing", "onboarding", "agents" ], result.book_attributes[:tag_names]

    assert_equal 10, result.units.size
    assert_equal(
      [ "welcome", "how-chapterwan-works", "human-setup", "agent-lifecycle", "create-first-book",
        "revisions-and-publishing", "library-and-reader", "operations-and-safety", "troubleshooting", "appendix" ],
      result.units.map { |u| u[:external_id] }
    )
    assert_equal [ "page", "page", "page", "page", "page", "page", "page", "page", "page", "section" ], result.units.map { |u| u[:kind] }
    assert_equal "dark", result.units.last[:theme]
  end

  private
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
