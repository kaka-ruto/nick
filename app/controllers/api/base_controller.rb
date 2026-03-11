class Api::BaseController < ActionController::API
  after_action :store_idempotent_response!, if: :write_request?

  private
    def authenticate_request!(required_scope:)
      key = ApiKey.authenticate(bearer_token)
      return render_error(:unauthorized, "unauthorized") if key.blank?

      key.update_column(:last_used_at, Time.current)
      Current.user = key.user
      Current.api_key = key

      unless key.allows?(required_scope)
        render json: { error: "forbidden", required_scope: required_scope }, status: :forbidden
        return false
      end

      return true unless write_request?

      if request.headers["Idempotency-Key"].blank?
        return render_error(:unprocessable_entity, "idempotency_key_required")
      end

      replay_idempotent_response!
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/, 1]
    end

    def replay_idempotent_response!
      @idempotency_key = Current.api_key.idempotency_keys.find_by(key: request.headers["Idempotency-Key"])
      return true if @idempotency_key.blank?

      if @idempotency_key.request_fingerprint != request_fingerprint
        return render_error(:conflict, "idempotency_key_conflict")
      end

      @idempotency_replayed = true
      render json: JSON.parse(@idempotency_key.response_body.presence || "{}"), status: @idempotency_key.response_status
      false
    rescue JSON::ParserError
      render_error(:internal_server_error, "idempotency_replay_failed")
    end

    def store_idempotent_response!
      return unless Current.api_key
      return if @idempotency_replayed
      return if request.headers["Idempotency-Key"].blank?

      Current.api_key.idempotency_keys.create!(
        key: request.headers["Idempotency-Key"],
        request_fingerprint: request_fingerprint,
        response_status: response.status,
        response_body: response.body
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    def request_fingerprint
      @request_fingerprint ||= Digest::SHA256.hexdigest([
        request.request_method,
        request.path,
        request.raw_post
      ].join("\n"))
    end

    def write_request?
      request.post? || request.patch? || request.put? || request.delete?
    end

    def render_error(status, code)
      render json: { error: code }, status: status
      false
    end
end
