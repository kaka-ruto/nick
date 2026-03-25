class Api::AgentsController < ApplicationController
  allow_unauthenticated_access only: %i[ create claim ]
  skip_forgery_protection only: %i[ create claim ]

  before_action :set_key, only: :claim

  def index
    agents = owned_agents
    render json: {
      agents: agents.map { |agent| serialize_agent(agent) },
      links: {
        self: "/api/agents",
        create: "/api/agents"
      }
    }
  end

  def show
    agent = owned_agents.friendly.find(params[:id])
    render json: {
      agent: serialize_agent(agent),
      links: {
        self: "/api/agents/#{agent.id}",
        claim: "/api/agents/#{agent.id}/claim",
        uploads: "/api/uploads"
      }
    }
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def create
    agent = Agent.create!(
      name: generated_name,
      username: generated_username
    )

    api_key, token = ApiKey.issue!(agent:, name: "bootstrap", scopes: ApiKey::SCOPES)
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
      claim_url: claim_url_for(claim.token),
      links: {
        self: "/api/agents/#{agent.id}",
        claim: "/api/agents/#{agent.id}/claim",
        uploads: "/api/uploads"
      }
    }, status: :created
  end

  def claim
    agent = Agent.friendly.find(params[:id])
    return render_forbidden unless @key&.agent_id == agent.id

    claim = AgentClaim.issue!(agent:)
    render json: {
      agent: {
        id: agent.id,
        status: agent.claimed? ? "claimed" : "unclaimed"
      },
      claim_url: claim_url_for(claim.token),
      links: {
        self: "/api/agents/#{agent.id}",
        claim: "/api/agents/#{agent.id}/claim"
      }
    }
  rescue ActiveRecord::RecordNotFound
    render_forbidden
  end

  private
    def set_key
      @key = ApiKey.authenticate(bearer_token)
      render_unauthorized if @key.blank?
    end

    def owned_agents
      return Agent.includes(:api_keys).order(created_at: :desc) if Current.user.can_administer?

      Current.user.claimed_agents.includes(:api_keys).order(created_at: :desc)
    end

    def serialize_agent(agent)
      {
        id: agent.id,
        username: agent.username,
        name: agent.name,
        status: agent.claimed? ? "claimed" : "unclaimed",
        owner_user_id: agent.owner_user_id,
        api_key_count: agent.api_keys.count,
        active_api_key_count: agent.api_keys.count { |key| key.revoked_at.nil? },
        last_key_used_at: agent.api_keys.map(&:last_used_at).compact.max
      }
    end

    def generated_name
      "Agent #{SecureRandom.hex(4)}"
    end

    def generated_username
      "agent-#{SecureRandom.hex(6)}"
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
