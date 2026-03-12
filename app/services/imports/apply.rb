class Imports::Apply
  def self.call(import:)
    new(import: import).call
  end

  def initialize(import:)
    @import = import
    @plan = import.plan.deep_symbolize_keys
  end

  def call
    Book.transaction do
      book = find_or_build_book
      ensure_revision_matches!(book)
      apply_book_attributes!(book)
      apply_units!(book)

      book.update!(import_revision: book.import_revision + 1)
      @import.update!(status: :applied, book: book, applied_at: Time.current, result: result(book))
    end
  rescue StandardError => error
    @import.update!(status: :failed, error_message: error.message)
    raise
  end

  private
    def find_or_build_book
      if @import.book_id.present?
        Book.find(@import.book_id)
      else
        Book.new
      end
    end

    def ensure_revision_matches!(book)
      return if @import.expected_revision.nil?
      return if book.import_revision == @import.expected_revision

      raise StandardError, "import revision mismatch"
    end

    def apply_book_attributes!(book)
      attributes = @plan.fetch(:book, {}).slice(:title, :subtitle, :author, :theme, :pricing_type, :price_cents, :published)
      category_name = @plan.fetch(:book, {})[:category_name]

      if category_name.present?
        category = Category.find_or_create_by!(slug: category_name.parameterize) { |c| c.name = category_name }
        attributes[:category_id] = category.id
      end

      book.assign_attributes(attributes)
      book.save!

      tag_names = @plan.fetch(:book, {})[:tag_names]
      book.assign_tags!(tag_names) if tag_names.present?

      if book.accesses.none?
        book.update_access(editors: [ @import.user_id ], readers: [ @import.user_id ])
      end
    end

    def apply_units!(book)
      units = Array(@plan[:units])
      seen = []

      units.each_with_index do |unit, index|
        external_id = unit.fetch(:external_id)
        seen << external_id

        mapping = book.book_units.find_by(external_id: external_id)
        if mapping&.content_sha256 == unit[:content_sha256]
          mapping.update!(position: index)
          next
        end

        leaf = upsert_leaf_for(book:, mapping:, unit:)

        attrs = {
          leaf_id: leaf.id,
          position: index,
          content_sha256: unit[:content_sha256]
        }

        if mapping
          mapping.update!(attrs)
        else
          book.book_units.create!(attrs.merge(external_id: external_id))
        end
      end

      book.book_units.where.not(external_id: seen).find_each do |mapping|
        mapping.leaf.trashed!
        mapping.destroy!
      end
    end

    def upsert_leaf_for(book:, mapping:, unit:)
      if mapping && compatible_leaf?(mapping.leaf, unit)
        mapping.leaf.tap do |existing_leaf|
          existing_leaf.edit(leaf_params: { title: unit[:title] }, leafable_params: leafable_params_for(unit))
        end
      else
        mapping&.leaf&.trashed!
        book.press(new_leafable_for(unit), title: unit[:title])
      end
    end

    def compatible_leaf?(leaf, unit)
      expected_type = unit[:kind] == "section" ? "Section" : "Page"
      leaf.leafable_type == expected_type
    end

    def new_leafable_for(unit)
      if unit[:kind] == "section"
        Section.new(body: unit[:body], theme: unit[:theme])
      else
        Page.new(body: unit[:body])
      end
    end

    def leafable_params_for(unit)
      if unit[:kind] == "section"
        { body: unit[:body], theme: unit[:theme] }
      else
        { body: unit[:body] }
      end
    end

    def result(book)
      {
        book_id: book.id,
        import_revision: book.import_revision + 1,
        units_count: book.book_units.count
      }
    end
end
