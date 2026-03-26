class User < ApplicationRecord
  extend FriendlyId
  friendly_id :username, use: :slugged

  include Role, Transferable
  pay_customer default_payment_processor: :stripe
  pay_merchant

  has_many :sessions, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :claimed_agents, class_name: "Agent", foreign_key: :owner_user_id, dependent: :nullify
  has_secure_password validations: false

  has_many :accesses, dependent: :destroy
  has_many :books, through: :accesses
  has_many :seller_books, class_name: "Book", foreign_key: :seller_user_id, dependent: :nullify
  has_many :book_sales_as_buyer, class_name: "BookSale", foreign_key: :buyer_user_id, dependent: :nullify
  has_many :book_sales_as_seller, class_name: "BookSale", foreign_key: :seller_user_id, dependent: :nullify
  belongs_to :seller_attention_book, class_name: "Book", optional: true
  has_many :leaves, through: :books

  after_create :grant_access_to_everyone_books

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  validates :username, presence: true, uniqueness: true
  validate :username_not_taken_by_other_principal
  before_validation :assign_default_username
  before_validation :normalize_username

  def current?
    self == Current.user
  end

  def email
    email_address
  end

  def customer_name
    name
  end

  def deactivate
    transaction do
      sessions.delete_all
      update! active: false, email_address: deactived_email_address
    end
  end

  def stripe_connect_ready?
    merchant = merchant_processor
    merchant.present? && merchant.onboarding_complete?
  end

  def needs_seller_onboarding?
    sell_paid_books.nil?
  end

  def can_sell_paid_books?
    sell_paid_books? && stripe_connect_ready?
  end

  private
    def assign_default_username
      return if username.present?

      self.username = email_address.to_s.split("@").first.presence || "user-#{SecureRandom.hex(4)}"
    end

    def normalize_username
      self.username = username.to_s.parameterize if username.present?
    end

    def username_not_taken_by_other_principal
      return if username.blank?

      taken = Agent.where(username: username).exists?
      errors.add(:username, "has already been taken") if taken
    end

    def deactived_email_address
      email_address&.gsub(/@/, "-deactivated-#{SecureRandom.uuid}@")
    end

    def grant_access_to_everyone_books
      all_accesses = Book.with_everyone_access.ids.collect { |id| { book_id: id, level: :reader } }
      accesses.insert_all(all_accesses)
    end
end
