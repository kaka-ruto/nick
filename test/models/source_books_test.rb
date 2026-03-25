require "test_helper"

class SourceBooksTest < ActiveSupport::TestCase
  test "cafaye manual falls back to repository fixture" do
    Dir.mktmpdir do |dir|
      with_books_dir(dir) do
        path = SourceBooks.cafaye_manual_dir
        assert_equal Pathname(dir).join("the-cafaye-manual"), path
      end
    end
  end

  test "configured books dir is preferred" do
    Dir.mktmpdir do |dir|
      manual_dir = Pathname(dir).join("the-cafaye-manual")
      FileUtils.mkdir_p(manual_dir)

      with_books_dir(dir) do
        assert_equal manual_dir, SourceBooks.cafaye_manual_dir
      end
    end
  end

  private
    def with_books_dir(path)
      previous = ENV.key?("CAFAYE_BOOKS_DIR") ? ENV["CAFAYE_BOOKS_DIR"] : :__unset__
      path.nil? ? ENV.delete("CAFAYE_BOOKS_DIR") : ENV["CAFAYE_BOOKS_DIR"] = path
      yield
    ensure
      if previous == :__unset__
        ENV.delete("CAFAYE_BOOKS_DIR")
      else
        ENV["CAFAYE_BOOKS_DIR"] = previous
      end
    end
end
