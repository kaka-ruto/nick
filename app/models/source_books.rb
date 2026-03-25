module SourceBooks
  module_function

  def root
    configured = ENV["CHAPTERWAN_BOOKS_DIR"].presence
    return Pathname(configured).expand_path if configured

    external = Pathname("~/Chapterwan/books").expand_path
    return external if external.directory?

    Rails.root.join("books")
  end

  def chapterwan_manual_dir
    preferred = root.join("the-chapterwan-manual")
    return preferred if preferred.directory?

    legacy = root.join("chapterwan-manual")
    return legacy if legacy.directory?

    preferred
  end
end
