module PagesHelper
  def word_count(content)
    return if content.blank?
    pluralize number_with_delimiter(content.split.size), "word"
  end

  def page_title(leaf, book)
    [ leaf.title, book.title, book.author ].reject(&:blank?).to_sentence(two_words_connector: " · ", words_connector: " · ", last_word_connector: " · ")
  end

  def sanitize_content(content)
    sanitize content, scrubber: HtmlScrubber.new
  end

  def house_toolbar(id:, &block)
    tag.div id: id, class: "house-toolbar", &block
  end

  def house_toolbar_button(action, &block)
    button_tag type: "button", class: "btn btn--link", data: { action: action }, &block
  end

  def house_toolbar_file_upload_button(&block)
    button_tag type: "button", class: "btn btn--link", data: { action: "upload" }, &block
  end
end
