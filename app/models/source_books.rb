module SourceBooks
  module_function

  def root
    configured = ENV["CHAPTERWAN_BOOKS_DIR"].presence
    return Pathname(configured).expand_path if configured

    external = Pathname("~/Code/books").expand_path
    return external if external.directory?

    Rails.root.join("books")
  end

  def chapterwan_manual_dir
    preferred = root.join("chapterwan-manual")
    return preferred if preferred.directory?

    legacy = root.join("the-chapterwan-manual")
    return legacy if legacy.directory?

    Rails.root.join("books/chapterwan-manual")
  end
end
