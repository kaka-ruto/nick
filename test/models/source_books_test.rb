require "test_helper"

class SourceBooksTest < ActiveSupport::TestCase
  test "chapterwan manual falls back to repository fixture" do
    Dir.mktmpdir do |dir|
      with_books_dir(dir) do
        path = SourceBooks.chapterwan_manual_dir
        assert_equal Pathname(dir).join("the-chapterwan-manual"), path
      end
    end
  end

  test "configured books dir is preferred" do
    Dir.mktmpdir do |dir|
      manual_dir = Pathname(dir).join("the-chapterwan-manual")
      FileUtils.mkdir_p(manual_dir)

      with_books_dir(dir) do
        assert_equal manual_dir, SourceBooks.chapterwan_manual_dir
      end
    end
  end

  private
    def with_books_dir(path)
      previous = ENV.key?("CHAPTERWAN_BOOKS_DIR") ? ENV["CHAPTERWAN_BOOKS_DIR"] : :__unset__
      path.nil? ? ENV.delete("CHAPTERWAN_BOOKS_DIR") : ENV["CHAPTERWAN_BOOKS_DIR"] = path
      yield
    ensure
      if previous == :__unset__
        ENV.delete("CHAPTERWAN_BOOKS_DIR")
      else
        ENV["CHAPTERWAN_BOOKS_DIR"] = previous
      end
    end
end
