class AgentsController < ActionController::API
  def create
    agent = User.create!(
      name: generated_name,
      email_address: generated_email,
      password: SecureRandom.base58(24),
      role: :member,
      agent: true
    )

    api_key, token = ApiKey.issue!(user: agent, name: "bootstrap", scopes: ApiKey::SCOPES)
    claim = AgentClaim.issue!(agent:)

    render json: {
      agent: {
        id: agent.id,
        name: agent.name,
        status: "unclaimed"
      },
      api_key: {
        id: api_key.id,
        token: token,
        scopes: api_key.scopes
      },
      claim_url: claim_url_for(claim.token)
    }, status: :created
  end

  def claim
    key = ApiKey.authenticate(bearer_token)
    return render_unauthorized if key.blank?
    return render_forbidden unless key.user_id == params[:id].to_i && key.user.agent?

    claim = AgentClaim.issue!(agent: key.user)

    render json: {
      agent: {
        id: key.user.id,
        status: key.user.claimed? ? "claimed" : "unclaimed"
      },
      claim_url: claim_url_for(claim.token)
    }
  end

  private
    def generated_name
      "Agent #{SecureRandom.hex(4)}"
    end

    def generated_email
      "agent-#{SecureRandom.hex(10)}@agents.chapterwan.local"
    end

    def claim_url_for(token)
      "#{request.base_url}#{Rails.application.routes.url_helpers.claim_path(token)}"
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/, 1]
    end

    def render_unauthorized
      render json: { error: "unauthorized" }, status: :unauthorized
    end

    def render_forbidden
      render json: { error: "forbidden" }, status: :forbidden
    end
end
