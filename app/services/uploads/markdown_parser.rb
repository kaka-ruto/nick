require "yaml"
require "zip"
require "json"

class Uploads::MarkdownParser
  Result = Struct.new(:book_attributes, :units, keyword_init: true)

  def self.call(content:, filename: nil)
    new(content: content, filename: filename).call
  end

  def initialize(content:, filename: nil)
    @content = content
    @filename = filename.to_s
    @front_matter_parser = FrontMatterParser::Parser.new(:md)
  end

  def call
    if zip_file?
      parse_zip_bundle
    else
      parse_single_markdown(@content.to_s)
    end
  end

  private
    def zip_file?
      @filename.downcase.end_with?(".zip")
    end

    def parse_zip_bundle
      manifest = {}
      markdown_entries = {}

      Zip::File.open_buffer(StringIO.new(@content)) do |zip|
        zip.each do |entry|
          next if entry.directory?

          path = entry.name
          data = entry.get_input_stream.read

          if path == "book.yml"
            manifest = parse_manifest(data)
          elsif path.end_with?(".md")
            markdown_entries[path] = data
          end
        end
      end

      order = ordered_paths(markdown_entries.keys, manifest)
      units = order.filter_map.with_index do |path, index|
        next unless markdown_entries.key?(path)

        build_unit_from_markdown(markdown_entries.fetch(path), index:, path:)
      end

      Result.new(
        book_attributes: parse_manifest_book_attributes(manifest),
        units: units
      )
    end

    def parse_single_markdown(raw_markdown)
      parsed = parse_markdown(raw_markdown)
      Result.new(
        book_attributes: parse_front_matter_book_attributes(parsed.front_matter || {}),
        units: [ build_unit(parsed:, index: 0, path: @filename.presence || "source.md") ]
      )
    end

    def parse_markdown(raw_markdown)
      utf8 = raw_markdown.to_s.dup.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace, replace: +"")
      @front_matter_parser.call(utf8)
    end

    def parse_manifest(raw)
      YAML.safe_load(raw.to_s, permitted_classes: [], aliases: false) || {}
    rescue Psych::SyntaxError
      {}
    end

    def parse_manifest_book_attributes(manifest)
      validate_manifest!(manifest)

      {}.tap do |attrs|
        attrs[:book_uid] = manifest["book_uid"].to_s.strip if manifest["book_uid"].present?
        attrs[:title] = manifest["title"].to_s.strip if manifest["title"].present?
        attrs[:subtitle] = manifest["subtitle"].to_s.strip if manifest["subtitle"].present?
        attrs[:author] = manifest["author"].to_s.strip if manifest["author"].present?
        attrs[:theme] = manifest["theme"].to_s.strip if manifest["theme"].present?
        attrs[:tag_names] = Array(manifest["tags"]).map(&:to_s)
        attrs[:category_name] = manifest["category"].to_s.strip if manifest["category"].present?
      end
    end

    def parse_front_matter_book_attributes(front_matter)
      {}.tap do |attrs|
        attrs[:book_uid] = front_matter["book_uid"].to_s.strip if front_matter["book_uid"].present?
        attrs[:title] = front_matter["title"].to_s.strip if front_matter["title"].present?
        attrs[:subtitle] = front_matter["subtitle"].to_s.strip if front_matter["subtitle"].present?
        attrs[:author] = front_matter["author"].to_s.strip if front_matter["author"].present?
        attrs[:theme] = front_matter["theme"].to_s.strip if front_matter["theme"].present?
        attrs[:tag_names] = Array(front_matter["tags"]).map(&:to_s)
        attrs[:category_name] = front_matter["category"].to_s.strip if front_matter["category"].present?
      end
    end

    def ordered_paths(paths, manifest)
      declared = Array(manifest["reading_order"]).map { |entry| entry.to_s.strip }.reject(&:blank?)
      return paths.sort if declared.empty?

      missing = declared - paths
      extra = paths - declared
      raise ArgumentError, "reading_order has missing files: #{missing.join(', ')}" if missing.any?
      raise ArgumentError, "reading_order has extra files not declared: #{extra.join(', ')}" if extra.any?

      declared
    end

    def build_unit_from_markdown(raw_markdown, index:, path:)
      parsed = parse_markdown(raw_markdown)
      build_unit(parsed:, index:, path:)
    end

    def build_unit(parsed:, index:, path:)
      front_matter = parsed.front_matter || {}
      title = front_matter["title"].to_s.strip.presence || heading_title(parsed.content.to_s) || fallback_title(path, index)
      kind = normalize_kind(front_matter["class"])
      body = parsed.content.to_s.strip
      external_id = required_external_id(front_matter:, path:)
      theme = front_matter["theme"].to_s.strip.presence

      payload = {
        kind: kind,
        title: title,
        body: body,
        theme: theme
      }

      {
        external_id: external_id,
        kind: kind,
        title: title,
        body: body,
        theme: theme,
        content_sha256: Digest::SHA256.hexdigest(JSON.dump(payload))
      }
    end

    def heading_title(content)
      content.to_s.each_line do |line|
        heading = line.match(/^#\s+(.+)$/)
        return heading[1].strip if heading
      end
      nil
    end

    def fallback_title(path, index)
      basename = File.basename(path, ".md").tr("_", " ").tr("-", " ").split.map(&:capitalize).join(" ")
      basename.presence || "Untitled #{index + 1}"
    end

    def required_external_id(front_matter:, path:)
      external_id = front_matter["id"].to_s.strip
      return external_id if external_id.present?

      raise ArgumentError, "missing required front matter id for #{path}"
    end

    def normalize_kind(klass)
      value = klass.to_s.downcase
      return "section" if value == "section"

      "page"
    end

    def validate_manifest!(manifest)
      required = %w[schema_version book_uid title author reading_order]
      missing = required.reject { |key| manifest[key].present? }
      raise ArgumentError, "book.yml missing required fields: #{missing.join(', ')}" if missing.any?
    end
end
