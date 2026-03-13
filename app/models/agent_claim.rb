class AgentClaim < ApplicationRecord
  CLAIM_TTL = 15.minutes

  belongs_to :agent, class_name: "User"
  belongs_to :claimed_by_user, class_name: "User", optional: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :pending, -> { where(claimed_at: nil).where("expires_at > ?", Time.current) }

  attr_reader :token

  def self.issue!(agent:, ttl: CLAIM_TTL)
    pending.where(agent:).delete_all

    token = SecureRandom.urlsafe_base64(32)
    create!(
      agent:,
      token_digest: digest(token),
      expires_at: ttl.from_now
    ).tap do |claim|
      claim.instance_variable_set(:@token, token)
    end
  end

  def self.consume!(token:, claimant:)
    claim = pending.find_by(token_digest: digest(token))
    return if claim.blank?

    transaction do
      claim.lock!
      return if claim.claimed_at.present? || claim.expires_at <= Time.current

      now = Time.current
      claim.update!(claimed_at: now, claimed_by_user: claimant)
      claim.agent.update!(claimed_at: now, claimed_by_user: claimant)
    end

    claim
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end
end
