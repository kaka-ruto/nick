class Agent < ApplicationRecord
  extend FriendlyId
  friendly_id :username, use: :slugged

  has_many :api_keys, dependent: :delete_all
  has_many :claims, class_name: "AgentClaim", dependent: :delete_all
  belongs_to :owner_user, class_name: "User", optional: true

  validates :name, :username, presence: true
  validates :username, uniqueness: true
  validate :username_not_taken_by_other_principal

  before_validation :normalize_username

  def claimed?
    claimed_at.present? && owner_user.present?
  end

  private
    def normalize_username
      self.username = username.to_s.parameterize if username.present?
    end

    def username_not_taken_by_other_principal
      return if username.blank?

      taken = User.where(username: username).exists?
      errors.add(:username, "has already been taken") if taken
    end
end
