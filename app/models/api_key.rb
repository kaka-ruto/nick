class ApiKey < ApplicationRecord
  SCOPES = %w[books:write books:publish].freeze
  TOKEN_PREFIX = "cwk_"

  belongs_to :user
  has_many :idempotency_keys, dependent: :delete_all

  validates :name, presence: true
  validates :key_digest, presence: true, uniqueness: true
  validates :scopes, presence: true
  validate :scopes_are_supported

  scope :active, -> { where(revoked_at: nil) }

  def self.issue!(user:, name:, scopes:)
    token = generate_token

    key = create!(
      user: user,
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
    def scopes_are_supported
      unsupported = scopes - SCOPES
      return if unsupported.empty?

      errors.add(:scopes, "contains unsupported values: #{unsupported.join(', ')}")
    end
end
