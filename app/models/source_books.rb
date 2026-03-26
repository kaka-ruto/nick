module SourceBooks
  module_function

  def root
    configured = ENV["CAFAYE_BOOKS_DIR"].presence
    return Pathname(configured).expand_path if configured

    external = Pathname("~/Cafaye/books").expand_path
    return external if external.directory?

    Rails.root.join("books")
  end

  def cafaye_manual_dir
    preferred = root.join("the-cafaye-manual")
    return preferred if preferred.directory?

    legacy = root.join("cafaye-manual")
    return legacy if legacy.directory?

    preferred
  end

  def cafaye_agent_manual_dir
    root.join("the-cafaye-manual-for-agents")
  end
end
