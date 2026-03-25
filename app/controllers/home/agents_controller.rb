class Home::AgentsController < ApplicationController
  def index
    @agents = owned_agents
  end

  def show
    @agent = owned_agents.friendly.find(params[:id])
    @api_keys = @agent.api_keys.order(created_at: :desc)
    @events = @api_keys.flat_map(&:events).sort_by(&:created_at).reverse.first(20)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private
    def owned_agents
      return Agent.includes(:api_keys).order(created_at: :desc) if Current.user.can_administer?

      Current.user.claimed_agents.includes(:api_keys).order(created_at: :desc)
    end
end
