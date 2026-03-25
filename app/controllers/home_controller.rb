class HomeController < ApplicationController
  def index
    @books = Book.accessable_or_published.ordered.limit(6)
    @agents = owned_agents.limit(6)
    @recent_uploads = Upload.includes(:book, :user).order(created_at: :desc).limit(8)
    @pending_publications = Book.accessable_or_published.where(published: false)
      .where.not(current_draft_revision_id: nil)
      .limit(8)
  end

  private
    def owned_agents
      return Agent.order(created_at: :desc) if Current.user.can_administer?

      Current.user.claimed_agents.order(created_at: :desc)
    end
end
