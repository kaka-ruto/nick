class Book < ApplicationRecord
  include Accessable, Sluggable

  has_many :leaves, dependent: :destroy
  has_one_attached :cover, dependent: :purge_later

  scope :ordered, -> { order(:title) }
  scope :published, -> { where(published: true) }
  scope :published_free, -> { published.where(pricing_type: :free) }

  enum :theme, %w[ black blue green magenta orange violet white ].index_by(&:itself), suffix: true, default: :blue
  enum :pricing_type, { free: "free", paid: "paid" }, default: :free

  before_validation :normalize_pricing

  validates :price_cents, numericality: { greater_than: 0, only_integer: true }, if: :paid?
  validates :price_cents, absence: true, if: :free?
  validate :paid_books_need_product_to_publish

  def press(leafable, leaf_params)
    leaves.create! leaf_params.merge(leafable: leafable)
  end

  def readable_by?(user: Current.user)
    return true if accessable?(user: user)
    published? && free?
  end

  def grant_reader_access(user)
    accesses.find_or_create_by!(user: user) do |access|
      access.level = :reader
    end
  end

  private
    def normalize_pricing
      self.price_cents = nil if free?
    end

    def paid_books_need_product_to_publish
      return unless published? && paid? && stripe_product_id.blank?

      errors.add(:published, "cannot be true for paid books without a Stripe product")
    end
end
