class Uploads::Apply
  def self.call(upload:, publish: false)
    new(upload:, publish: publish).call
  end

  def initialize(upload:, publish:)
    @upload = upload
    @plan = upload.plan.deep_symbolize_keys
    @publish = publish
  end

  def call
    Book.transaction do
      book = find_or_build_book
      ensure_revision_matches!(book)
      apply_book_attributes!(book)
      apply_units!(book)

      revision = create_revision!(book)
      book.update!(
        import_revision: revision.number,
        current_draft_revision: revision,
        published_revision: (@publish ? revision : book.published_revision),
        published: @publish || book.published?
      )
      @upload.update!(status: :accepted, book: book, applied_at: Time.current, result: result(book, revision))
    end
  rescue StandardError => error
    @upload.update!(status: :failed, error_message: error.message)
    raise
  end

  private
    def find_or_build_book
      if @upload.book_id.present?
        Book.find(@upload.book_id)
      else
        uid = @plan.fetch(:book, {})[:book_uid].presence
        uid.present? ? Book.find_or_initialize_by(book_uid: uid) : Book.new
      end
    end

    def ensure_revision_matches!(book)
      return if @upload.expected_revision.nil?
      return if book.import_revision == @upload.expected_revision

      raise StandardError, "upload revision mismatch"
    end

    def apply_book_attributes!(book)
      attributes = @plan.fetch(:book, {}).slice(:title, :subtitle, :author, :theme)
      category_name = @plan.fetch(:book, {})[:category_name]
      book_uid = @plan.fetch(:book, {})[:book_uid].presence

      if category_name.present?
        category = Category.find_or_create_by!(slug: category_name.parameterize) { |c| c.name = category_name }
        attributes[:category_id] = category.id
      end

      attributes[:book_uid] = book_uid if book_uid.present?
      book.assign_attributes(attributes)
      book.save!

      tag_names = @plan.fetch(:book, {})[:tag_names]
      book.assign_tags!(tag_names) if tag_names.present?

      if book.accesses.none?
        book.update_access(editors: [ @upload.user_id ], readers: [ @upload.user_id ])
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

    def create_revision!(book)
      number = book.book_revisions.maximum(:number).to_i + 1
      BookRevision.create!(
        book: book,
        upload: @upload,
        number: number,
        source_sha256: @upload.source_sha256,
        metadata: @plan.fetch(:book, {}),
        units: Array(@plan[:units])
      )
    end

    def result(book, revision)
      {
        book_id: book.id,
        book_revision_id: revision.id,
        revision_number: revision.number,
        units_count: book.book_units.count
      }
    end
end
