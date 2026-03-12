class Ingestions::Apply
  def self.call(ingestion:)
    new(ingestion: ingestion).call
  end

  def initialize(ingestion:)
    @ingestion = ingestion
    @plan = ingestion.plan.deep_symbolize_keys
  end

  def call
    Book.transaction do
      book = find_or_build_book
      ensure_revision_matches!(book)
      apply_book_attributes!(book)
      apply_units!(book)

      book.update!(ingestion_revision: book.ingestion_revision + 1)
      @ingestion.update!(status: :applied, book: book, applied_at: Time.current, result: result(book))
    end
  rescue StandardError => error
    @ingestion.update!(status: :failed, error_message: error.message)
    raise
  end

  private
    def find_or_build_book
      if @ingestion.book_id.present?
        Book.find(@ingestion.book_id)
      else
        Book.new
      end
    end

    def ensure_revision_matches!(book)
      return if @ingestion.expected_revision.nil?
      return if book.ingestion_revision == @ingestion.expected_revision

      raise StandardError, "ingestion revision mismatch"
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
        book.update_access(editors: [ @ingestion.user_id ], readers: [ @ingestion.user_id ])
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

        leaf = if mapping
          mapping.leaf.tap do |existing_leaf|
            existing_leaf.edit(leaf_params: { title: unit[:title] }, leafable_params: { body: unit[:body] })
          end
        else
          book.press(Page.new(body: unit[:body]), title: unit[:title])
        end

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

    def result(book)
      {
        book_id: book.id,
        ingestion_revision: book.ingestion_revision + 1,
        units_count: book.book_units.count
      }
    end
end
