class HomeController < ApplicationController
  before_action :redirect_to_seller_onboarding_if_needed

  def index
    @seller_attention_required = Current.user.seller_attention_required?
    @seller_attention_reason = Current.user.seller_attention_reason
    @seller_attention_book = Current.user.seller_attention_book
    @books = Book.accessable_or_published.ordered.limit(6)
    @agents = owned_agents.limit(6)
    @recent_uploads = Upload.includes(:book, :user).order(created_at: :desc).limit(8)
    @pending_publications = Book.accessable_or_published.where(published: false)
      .where.not(current_draft_revision_id: nil)
      .limit(8)
  end

  private
    def redirect_to_seller_onboarding_if_needed
      return unless Current.user.needs_seller_onboarding?

      redirect_to home_seller_onboarding_url
    end

    def owned_agents
      return Agent.order(created_at: :desc) if Current.user.can_administer?

      Current.user.claimed_agents.order(created_at: :desc)
    end
end
