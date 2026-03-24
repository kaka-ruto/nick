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
      Uploads::ProjectUnits.call(book:, units: @plan[:units])

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
      base_revision = @upload.base_revision_id || @upload.expected_revision
      return if base_revision.nil?
      return if book.import_revision == base_revision

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

    def create_revision!(book)
      number = book.book_revisions.maximum(:number).to_i + 1
      previous_units = book.book_revisions.order(number: :desc).first&.units || []
      next_units = Array(@plan[:units])

      BookRevision.create!(
        book: book,
        upload: @upload,
        number: number,
        source_sha256: @upload.source_sha256,
        metadata: @plan.fetch(:book, {}),
        units: next_units,
        diff_summary: Uploads::RevisionDiff.call(previous_units:, next_units:)
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
