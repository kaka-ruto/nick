class ApiKeysController < ApplicationController
  before_action :ensure_can_administer
  before_action :set_api_key, only: %i[ revoke rotate ]

  def index
    render json: { api_keys: ApiKey.includes(:user, :agent).order(created_at: :desc).map { |key| serialize_api_key(key) } }
  end

  def create
    user = User.find(params.fetch(:user_id, Current.user.id))
    api_key, token = ApiKey.issue!(user: user, name: params.require(:name), scopes: Array(params.require(:scopes)))

    render json: { api_key: serialize_api_key(api_key), token: token }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: "invalid_record", detail: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def revoke
    @api_key.revoke!
    render json: { api_key: serialize_api_key(@api_key) }
  end

  def rotate
    token = @api_key.rotate!
    render json: { api_key: serialize_api_key(@api_key), token: token }
  end

  private
    def set_api_key
      @api_key = ApiKey.find(params[:id])
    end

    def serialize_api_key(key)
      {
        id: key.id,
        name: key.name,
        user_id: key.user_id,
        user_name: key.user&.name,
        agent_id: key.agent_id,
        agent_name: key.agent&.name,
        scopes: key.scopes,
        last_used_at: key.last_used_at,
        revoked_at: key.revoked_at,
        created_at: key.created_at,
        updated_at: key.updated_at
      }
    end
end
