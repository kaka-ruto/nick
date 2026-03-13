class Sessions::OauthController < ApplicationController
  allow_unauthenticated_access only: %i[ callback failure ]

  def callback
    auth = request.env["omniauth.auth"]
    return redirect_to new_session_url unless auth

    user = find_or_create_user_for(auth)
    start_new_session_for(user)

    if (claim_token = session.delete(:agent_claim_token)).present?
      AgentClaim.consume!(token: claim_token, claimant: user)
    end

    redirect_to root_url
  end

  def failure
    redirect_to new_session_url
  end

  private
    def find_or_create_user_for(auth)
      identity = Identity.find_or_initialize_by(provider: auth.provider, uid: auth.uid)
      return identity.user if identity.user.present?

      email = resolved_email_for(auth)
      user = User.find_by(email_address: email)

      if user.blank?
        user = User.create!(
          name: auth.info.name.presence || auth.info.nickname.presence || "User #{SecureRandom.hex(3)}",
          email_address: email,
          password: SecureRandom.base58(24),
          role: :member
        )
      end

      identity.user = user
      identity.email = email
      identity.save!
      user
    end

    def resolved_email_for(auth)
      email = auth.info.email.to_s.downcase
      return email if email.present?

      "#{auth.provider}-#{auth.uid}@oauth.chapterwan.local"
    end
end
