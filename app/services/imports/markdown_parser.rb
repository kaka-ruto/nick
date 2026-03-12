class Imports::MarkdownParser
  Result = Struct.new(:book_attributes, :units, keyword_init: true)

  def self.call(content:)
    new(content: content).call
  end

  def initialize(content:)
    @content = content
  end

  def call
    parser = FrontMatterParser::Parser.new(:md)
    parsed = parser.call(@content)

    Result.new(
      book_attributes: parse_book_attributes(parsed.front_matter || {}),
      units: parse_units(parsed.content.to_s)
    )
  end

  private
    def parse_book_attributes(front_matter)
      {}.tap do |attrs|
        attrs[:title] = front_matter["title"].to_s.strip if front_matter["title"].present?
        attrs[:subtitle] = front_matter["subtitle"].to_s.strip if front_matter["subtitle"].present?
        attrs[:author] = front_matter["author"].to_s.strip if front_matter["author"].present?
        attrs[:theme] = front_matter["theme"].to_s.strip if front_matter["theme"].present?
        attrs[:pricing_type] = front_matter["pricing_type"].to_s.strip if front_matter["pricing_type"].present?
        attrs[:price_cents] = front_matter["price_cents"].to_i if front_matter["price_cents"].present?
        attrs[:published] = ActiveModel::Type::Boolean.new.cast(front_matter["published"]) unless front_matter["published"].nil?
        attrs[:tag_names] = Array(front_matter["tags"]).map(&:to_s)
        attrs[:category_name] = front_matter["category"].to_s.strip if front_matter["category"].present?
      end
    end

    def parse_units(content)
      sections = split_sections(content)
      return [build_unit(title: "Untitled", body: content.to_s.strip, index: 0)] if sections.empty?

      sections.each_with_index.map do |section, index|
        build_unit(title: section[:title], body: section[:body], index: index)
      end
    end

    def split_sections(content)
      lines = content.to_s.lines
      sections = []
      current = nil

      lines.each do |line|
        if (heading = line.match(/^#\s+(.+)$/))
          sections << current if current
          current = { title: heading[1].strip, body: line }
        elsif current
          current[:body] << line
        end
      end

      sections << current if current
      sections.compact
    end

    def build_unit(title:, body:, index:)
      normalized_title = title.presence || "Untitled #{index + 1}"
      normalized_body = body.to_s.strip
      slug = normalized_title.parameterize.presence || "unit-#{index + 1}"

      {
        external_id: "#{format('%03d', index + 1)}-#{slug}",
        title: normalized_title,
        body: normalized_body,
        content_sha256: Digest::SHA256.hexdigest(normalized_body)
      }
    end
end
