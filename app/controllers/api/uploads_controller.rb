class Api::UploadsController < Api::BaseController
  before_action :set_upload, only: :show

  def create
    return unless authenticate_request!(required_scope: "books:write")

    source_bundle = params[:source_bundle] || params[:source_file]
    return render_error(:bad_request, "source_bundle_required") if source_bundle.blank?

    source_content = source_bundle.read
    source_bundle.rewind

    upload = Upload.create!(
      api_key: Current.api_key,
      user: Current.user,
      book_id: params[:book_id],
      book_uid: params[:book_uid],
      expected_revision: params[:expected_revision],
      base_revision_id: params[:base_revision_id] || params[:expected_revision],
      source_commit: params[:source_commit],
      agent_run_id: params[:agent_run_id],
      source_sha256: Digest::SHA256.hexdigest(source_content),
      parser_version: Upload::PARSER_VERSION,
      status: :received
    )

    upload.source_bundle.attach(
      io: source_bundle,
      filename: source_bundle.original_filename,
      content_type: source_bundle.content_type
    )

    upload.update!(status: :validating)
    parser_result = Uploads::MarkdownParser.call(content: source_content, filename: source_bundle.original_filename)
    upload.update!(
      status: :parsed,
      warnings: [],
      plan: {
        book: parser_result.book_attributes,
        units: parser_result.units
      }
    )

    publish_requested = ActiveModel::Type::Boolean.new.cast(params[:publish] || params[:apply])
    if publish_requested && !Current.api_key.allows?("books:publish")
      raise StandardError, "books:publish scope required when publish=true"
    end

    upload.update!(status: :applying)
    Uploads::Apply.call(upload:, publish: publish_requested)

    record_agent_action!(action: "book.upload.create", subject: upload, metadata: { book_id: upload.book_id })
    render json: { upload: serialize_upload(upload.reload) }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    upload&.update(validation_errors: [ error.record.errors.full_messages.to_sentence ])
    render json: { error: "invalid_record", detail: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue StandardError => error
    upload&.update(status: :failed, error_message: error.message, validation_errors: [ error.message ])
    render json: { error: "upload_failed", detail: error.message }, status: :unprocessable_entity
  end

  def show
    return unless authenticate_request!(required_scope: "books:write")

    render json: { upload: serialize_upload(@upload) }
  end

  private
    def set_upload
      @upload = Upload.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "not_found" }, status: :not_found
    end

    def serialize_upload(upload)
      {
        id: upload.id,
        book_id: upload.book_id,
        status: upload.status,
        parser_version: upload.parser_version,
        expected_revision: upload.expected_revision,
        base_revision_id: upload.base_revision_id,
        source_commit: upload.source_commit,
        agent_run_id: upload.agent_run_id,
        source_sha256: upload.source_sha256,
        applied_at: upload.applied_at,
        error_message: upload.error_message,
        validation_errors: upload.validation_errors,
        warnings: upload.warnings,
        build_log: upload.build_log,
        plan: upload.plan,
        result: upload.result,
        created_at: upload.created_at,
        updated_at: upload.updated_at,
        links: {
          self: "/api/uploads/#{upload.id}",
          book: upload.book_id.present? ? "/api/books/#{upload.book_id}" : nil,
          revisions: upload.book_id.present? ? "/api/books/#{upload.book_id}/revisions" : nil
        }.compact
      }
    end
end
