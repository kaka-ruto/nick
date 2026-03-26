class ClaimsController < ApplicationController
  allow_unauthenticated_access only: %i[ show start ]

  SUPPORTED_PROVIDERS = %w[ github google_oauth2 ].freeze

  before_action :load_claim

  def show
    return head :not_found unless @claim

    if signed_in?
      AgentClaim.consume!(token: params[:token], claimant: Current.user)
      return redirect_to(Current.user.needs_seller_onboarding? ? home_seller_onboarding_url : home_url)
    end
  end

  def start
    return head :not_found unless @claim

    provider = params[:provider].to_s
    return head :unprocessable_entity unless SUPPORTED_PROVIDERS.include?(provider)

    session[:agent_claim_token] = params[:token]
    redirect_to "/auth/#{provider}", allow_other_host: false
  end

  private
    def load_claim
      digest = AgentClaim.digest(params[:token])
      @claim = AgentClaim.pending.find_by(token_digest: digest)
    end
end
