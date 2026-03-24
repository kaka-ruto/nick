class Api::BooksController < Api::BaseController
  def create
    return unless authenticate_request!(required_scope: "books:write")

    book = Book.create!(book_params)
    book.assign_tags!(tag_names)
    book.update_access(editors: [ Current.user.id ], readers: [ Current.user.id ])
    record_agent_action!(action: "book.create", subject: book)

    render json: { book: serialize_book(book) }, status: :created
  end

  def update
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book

    @book.update!(book_params)
    @book.assign_tags!(tag_names) if params.dig(:book, :tag_names).present?
    record_agent_action!(action: "book.update", subject: @book)
    render json: { book: serialize_book(@book) }
  end

  def set_pricing
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book

    @book.update!(pricing_params)
    record_agent_action!(action: "book.pricing.set", subject: @book, metadata: pricing_params.to_h)
    render json: { book: serialize_book(@book) }
  end

  def set_publication
    return unless authenticate_request!(required_scope: "books:publish")
    return unless load_editable_book

    @book.update!(publication_params)
    record_agent_action!(action: "book.publication.set", subject: @book, metadata: publication_params.to_h)
    render json: { book: serialize_book(@book) }
  end

  def publish_revision
    return unless authenticate_request!(required_scope: "books:publish")
    return unless load_editable_book

    revision_id = params[:revision_id]
    return render json: { error: "revision_id_required" }, status: :unprocessable_entity if revision_id.blank?

    revision = @book.book_revisions.find(revision_id)
    Uploads::ProjectUnits.call(book: @book, units: revision.units)
    @book.update!(published_revision: revision, published: true)
    record_agent_action!(action: "book.revision.publish", subject: @book, metadata: { revision_id: revision.id })
    render json: { book: serialize_book(@book), published_revision_id: revision.id }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  def unpublish
    return unless authenticate_request!(required_scope: "books:publish")
    return unless load_editable_book

    @book.update!(published_revision: nil, published: false)
    record_agent_action!(action: "book.revision.unpublish", subject: @book)
    render json: { book: serialize_book(@book), published_revision_id: nil }
  end

  def revisions
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book(id_key: :book_id)

    revisions = @book.book_revisions.order(number: :desc)
    render json: {
      revisions: revisions.map { |revision| serialize_revision(revision) },
      current_draft_revision_id: @book.current_draft_revision_id,
      published_revision_id: @book.published_revision_id
    }
  end

  def show_revision
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book(id_key: :book_id)

    revision = @book.book_revisions.find(params[:revision_id])
    render json: { revision: serialize_revision(revision).merge(units: revision.units, metadata: revision.metadata) }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  def source_for_revision
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book(id_key: :book_id)

    revision = @book.book_revisions.find(params[:revision_id])
    upload = revision.upload
    return render json: { error: "source_missing" }, status: :not_found unless upload.source_bundle.attached?

    render json: {
      source: {
        upload_id: upload.id,
        filename: upload.source_bundle.filename.to_s,
        content_type: upload.source_bundle.content_type,
        byte_size: upload.source_bundle.byte_size,
        url: rails_blob_path(upload.source_bundle, only_path: true)
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  def source
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book

    revision = @book.current_draft_revision || @book.book_revisions.order(number: :desc).first
    return render json: { error: "source_missing" }, status: :not_found if revision.blank?

    upload = revision.upload
    return render json: { error: "source_missing" }, status: :not_found unless upload.source_bundle.attached?

    render json: {
      source: {
        upload_id: upload.id,
        book_revision_id: revision.id,
        revision_number: revision.number,
        filename: upload.source_bundle.filename.to_s,
        content_type: upload.source_bundle.content_type,
        byte_size: upload.source_bundle.byte_size,
        url: rails_blob_path(upload.source_bundle, only_path: true)
      }
    }
  end

  def upload_cover
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book

    if params[:cover].present?
      @book.cover.attach(params[:cover])
    elsif ActiveModel::Type::Boolean.new.cast(params[:remove_cover])
      @book.cover.purge if @book.cover.attached?
    end
    record_agent_action!(action: "book.cover.upload", subject: @book, metadata: { cover_attached: @book.cover.attached? })

    render json: { book: serialize_book(@book) }
  end

  def upsert_chapter
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book(id_key: :book_id)

    leaf = upsert_leaf(type: Section, leafable_params: chapter_params)
    record_agent_action!(action: "book.chapter.upsert", subject: leaf, metadata: { book_id: @book.id })
    render json: { chapter: serialize_leaf(leaf) }, status: leaf.previously_new_record? ? :created : :ok
  end

  def upsert_page
    return unless authenticate_request!(required_scope: "books:write")
    return unless load_editable_book(id_key: :book_id)

    leaf = upsert_leaf(type: Page, leafable_params: page_params)
    record_agent_action!(action: "book.page.upsert", subject: leaf, metadata: { book_id: @book.id })
    render json: { page: serialize_leaf(leaf) }, status: leaf.previously_new_record? ? :created : :ok
  end

  private
    def load_editable_book(id_key: :id)
      @book = Book.accessable_or_published.find(params[id_key])
      return true if @book.editable?

      head :forbidden
      false
    rescue ActiveRecord::RecordNotFound
      render json: { error: "not_found" }, status: :not_found
      false
    end

    def book_params
      params.require(:book).permit(:title, :subtitle, :author, :everyone_access, :theme, :category_id)
    end

    def tag_names
      params.dig(:book, :tag_names)
    end

    def pricing_params
      params.require(:book).permit(:pricing_type, :price_cents)
    end

    def publication_params
      params.require(:book).permit(:published)
    end

    def chapter_params
      params.require(:chapter).permit(:body, :theme)
    end

    def page_params
      params.require(:page).permit(:body)
    end

    def leaf_params
      params.fetch(:leaf, {}).permit(:title)
    end

    def upsert_leaf(type:, leafable_params:)
      if params[:leaf_id].present?
        leaf = @book.leaves.active.find(params[:leaf_id])
        if leaf.leafable_type != type.name
          render json: { error: "leaf_type_mismatch", expected: type.name, actual: leaf.leafable_type }, status: :unprocessable_entity
          return
        end

        leaf.edit(leafable_params: leafable_params, leaf_params: leaf_params)
        leaf
      else
        @book.press(type.new(leafable_params), default_leaf_params(type).merge(leaf_params))
      end
    end

    def default_leaf_params(type)
      { title: type.model_name.human }
    end

    def serialize_book(book)
      {
        id: book.id,
        title: book.title,
        subtitle: book.subtitle,
        author: book.author,
        theme: book.theme,
        everyone_access: book.everyone_access,
        pricing_type: book.pricing_type,
        price_cents: book.price_cents,
        published: book.published,
        cover_attached: book.cover.attached?,
        category: book.category&.name,
        tags: book.tag_names
      }
    end

    def serialize_leaf(leaf)
      {
        id: leaf.id,
        title: leaf.title,
        leafable_type: leaf.leafable_type,
        leafable_id: leaf.leafable_id,
        position_score: leaf.position_score
      }
    end

    def serialize_revision(revision)
      {
        id: revision.id,
        number: revision.number,
        source_sha256: revision.source_sha256,
        upload_id: revision.upload_id,
        created_at: revision.created_at
      }
    end
end
