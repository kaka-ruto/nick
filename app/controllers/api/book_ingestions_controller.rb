class Api::BookIngestionsController < Api::BaseController
  before_action :set_ingestion, only: %i[ show apply ]

  def create
    return unless authenticate_request!(required_scope: "books:write")

    source_file = params[:source_file]
    return render_error(:bad_request, "source_file_required") if source_file.blank?

    source_content = source_file.read
    source_content = source_content.force_encoding("UTF-8")
    source_content = source_content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    source_file.rewind

    ingestion = BookIngestion.create!(
      api_key: Current.api_key,
      user: Current.user,
      book_id: params[:book_id],
      expected_revision: params[:expected_revision],
      source_sha256: Digest::SHA256.hexdigest(source_content),
      parser_version: BookIngestion::PARSER_VERSION
    )

    ingestion.source_file.attach(io: source_file, filename: source_file.original_filename, content_type: source_file.content_type)

    parser_result = Ingestions::MarkdownParser.call(content: source_content)
    ingestion.update!(
      status: :parsed,
      plan: {
        book: parser_result.book_attributes,
        units: parser_result.units
      }
    )

    apply_ingestion(ingestion) if ActiveModel::Type::Boolean.new.cast(params[:apply])

    record_agent_action!(action: "book.ingestion.create", subject: ingestion, metadata: { book_id: ingestion.book_id })
    render json: { ingestion: serialize_ingestion(ingestion.reload) }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: "invalid_record", detail: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue StandardError => error
    render json: { error: "ingestion_apply_failed", detail: error.message }, status: :unprocessable_entity
  end

  def show
    return unless authenticate_request!(required_scope: "books:write")

    render json: { ingestion: serialize_ingestion(@ingestion) }
  end

  def apply
    return unless authenticate_request!(required_scope: "books:write")

    apply_ingestion(@ingestion)

    record_agent_action!(action: "book.ingestion.apply", subject: @ingestion, metadata: { book_id: @ingestion.book_id })
    render json: { ingestion: serialize_ingestion(@ingestion.reload) }
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: "invalid_record", detail: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue StandardError => error
    render json: { error: "ingestion_apply_failed", detail: error.message }, status: :unprocessable_entity
  end

  private
    def set_ingestion
      @ingestion = BookIngestion.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "not_found" }, status: :not_found
    end

    def apply_ingestion(ingestion)
      unless Current.api_key.allows?("books:publish") || !ingestion.plan.dig("book", "published")
        raise StandardError, "books:publish scope required when published=true"
      end

      Ingestions::Apply.call(ingestion: ingestion)
    end

    def serialize_ingestion(ingestion)
      {
        id: ingestion.id,
        book_id: ingestion.book_id,
        status: ingestion.status,
        parser_version: ingestion.parser_version,
        expected_revision: ingestion.expected_revision,
        source_sha256: ingestion.source_sha256,
        applied_at: ingestion.applied_at,
        error_message: ingestion.error_message,
        plan: ingestion.plan,
        result: ingestion.result,
        created_at: ingestion.created_at,
        updated_at: ingestion.updated_at
      }
    end
end
