class ApiKey < ApplicationRecord
  SCOPES = %w[books:write books:publish].freeze
  TOKEN_PREFIX = "cwk_"

  belongs_to :user, optional: true
  belongs_to :agent, optional: true
  has_many :idempotency_keys, dependent: :delete_all
  has_many :events, class_name: "ApiKeyEvent", dependent: :delete_all

  validates :name, presence: true
  validates :key_digest, presence: true, uniqueness: true
  validates :scopes, presence: true
  validate :scopes_are_supported

  scope :active, -> { where(revoked_at: nil) }

  validate :exactly_one_principal

  def self.issue!(user: nil, agent: nil, name:, scopes:)
    token = generate_token

    key = create!(
      user: user,
      agent: agent,
      name: name,
      scopes: scopes,
      key_digest: digest(token)
    )

    [ key, token ]
  end

  def self.authenticate(token)
    return if token.blank?

    active.find_by(key_digest: digest(token))
  end

  def self.generate_token
    "#{TOKEN_PREFIX}#{SecureRandom.hex(24)}"
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def allows?(scope)
    scopes.include?(scope)
  end

  def principal
    agent || user
  end

  def rotate!
    token = self.class.generate_token

    update!(
      key_digest: self.class.digest(token),
      revoked_at: nil,
      last_used_at: nil
    )

    token
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private
    def exactly_one_principal
      if user.present? == agent.present?
        errors.add(:base, "must belong to exactly one principal")
      end
    end

    def scopes_are_supported
      unsupported = scopes - SCOPES
      return if unsupported.empty?

      errors.add(:scopes, "contains unsupported values: #{unsupported.join(', ')}")
    end
end
