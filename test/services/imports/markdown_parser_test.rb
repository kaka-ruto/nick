require "test_helper"
require "zip"

class Imports::MarkdownParserTest < ActiveSupport::TestCase
  test "parses single markdown file using front matter" do
    markdown = <<~MD
      ---
      title: Single File
      class: Section
      theme: dark
      category: Engineering
      tags:
        - single
      ---
      Body
    MD

    result = Imports::MarkdownParser.call(content: markdown, filename: "single.md")

    assert_equal "Single File", result.book_attributes[:title]
    assert_equal "Engineering", result.book_attributes[:category_name]
    assert_equal [ "single" ], result.book_attributes[:tag_names]

    assert_equal 1, result.units.size
    unit = result.units.first
    assert_equal "section", unit[:kind]
    assert_equal "Single File", unit[:title]
    assert_equal "dark", unit[:theme]
  end

  test "parses zip bundle with manifest ordering and kinds" do
    zip_data = build_zip_from_directory(Rails.root.join("books/the-chapterwan-manual"))

    result = Imports::MarkdownParser.call(content: zip_data, filename: "the-chapterwan-manual.zip")

    assert_equal "The Chapterwan Manual", result.book_attributes[:title]
    assert_equal "General", result.book_attributes[:category_name]
    assert_equal [ "manual", "publishing", "onboarding" ], result.book_attributes[:tag_names]

    assert_equal 4, result.units.size
    assert_equal [ "welcome", "writing-markdown", "publishing", "appendix" ], result.units.map { |u| u[:external_id] }
    assert_equal [ "page", "page", "page", "section" ], result.units.map { |u| u[:kind] }
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
end
