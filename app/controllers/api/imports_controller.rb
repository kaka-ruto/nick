class Api::ImportsController < Api::BaseController
  before_action :set_import, only: %i[ show apply ]

  def create
    return unless authenticate_request!(required_scope: "books:write")

    source_file = params[:source_file]
    return render_error(:bad_request, "source_file_required") if source_file.blank?

    source_content = source_file.read
    source_file.rewind

    import = Import.create!(
      api_key: Current.api_key,
      user: Current.user,
      book_id: params[:book_id],
      expected_revision: params[:expected_revision],
      source_sha256: Digest::SHA256.hexdigest(source_content),
      parser_version: Import::PARSER_VERSION
    )

    import.source_file.attach(io: source_file, filename: source_file.original_filename, content_type: source_file.content_type)

    parser_result = Imports::MarkdownParser.call(content: source_content, filename: source_file.original_filename)
    import.update!(
      status: :parsed,
      plan: {
        book: parser_result.book_attributes,
        units: parser_result.units
      }
    )

    apply_import(import) if ActiveModel::Type::Boolean.new.cast(params[:apply])

    record_agent_action!(action: "book.import.create", subject: import, metadata: { book_id: import.book_id })
    render json: { import: serialize_import(import.reload) }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: "invalid_record", detail: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue StandardError => error
    render json: { error: "import_apply_failed", detail: error.message }, status: :unprocessable_entity
  end

  def show
    return unless authenticate_request!(required_scope: "books:write")

    render json: { import: serialize_import(@import) }
  end

  def apply
    return unless authenticate_request!(required_scope: "books:write")

    apply_import(@import)

    record_agent_action!(action: "book.import.apply", subject: @import, metadata: { book_id: @import.book_id })
    render json: { import: serialize_import(@import.reload) }
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: "invalid_record", detail: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue StandardError => error
    render json: { error: "import_apply_failed", detail: error.message }, status: :unprocessable_entity
  end

  private
    def set_import
      @import = Import.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "not_found" }, status: :not_found
    end

    def apply_import(import)
      unless Current.api_key.allows?("books:publish") || !import.plan.dig("book", "published")
        raise StandardError, "books:publish scope required when published=true"
      end

      Imports::Apply.call(import: import)
    end

    def serialize_import(import)
      {
        id: import.id,
        book_id: import.book_id,
        status: import.status,
        parser_version: import.parser_version,
        expected_revision: import.expected_revision,
        source_sha256: import.source_sha256,
        applied_at: import.applied_at,
        error_message: import.error_message,
        plan: import.plan,
        result: import.result,
        created_at: import.created_at,
        updated_at: import.updated_at
      }
    end
end
