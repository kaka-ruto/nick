class Book < ApplicationRecord
  include MoneyRails::ActiveRecord::Monetizable
  include Accessable, Sluggable

  has_many :leaves, dependent: :destroy
  has_many :uploads, dependent: :delete_all
  has_many :book_revisions, dependent: :delete_all
  has_many :book_units, dependent: :delete_all
  belongs_to :current_draft_revision, class_name: "BookRevision", optional: true
  belongs_to :published_revision, class_name: "BookRevision", optional: true
  belongs_to :category
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags
  has_many :book_views, dependent: :delete_all
  has_many :book_sales, dependent: :delete_all
  has_one_attached :cover, dependent: :purge_later
  belongs_to :seller_user, class_name: "User", optional: true

  scope :ordered, -> { order(:title) }
  scope :published, -> { where(published: true) }
  scope :published_free, -> { published.where(pricing_type: :free) }
  scope :popular, ->(days = BookView::WINDOW_DAYS) {
    left_joins(:book_views)
      .where("book_views.viewed_on >= ? OR book_views.id IS NULL", days.days.ago.to_date)
      .group("books.id")
      .order(Arel.sql("COUNT(book_views.id) DESC"), :title)
  }

  enum :theme, %w[ black blue green magenta orange violet white ].index_by(&:itself), suffix: true, default: :blue
  enum :pricing_type, { free: "free", paid: "paid" }, default: :free
  monetize :price_cents, with_currency: :price_currency, allow_nil: true

  before_validation :normalize_pricing
  before_validation :assign_default_category

  validates :price_cents, numericality: { greater_than: 0, only_integer: true }, if: :paid?
  validates :price_cents, absence: true, if: :free?
  validates :category, presence: true
  validate :max_five_tags
  validate :paid_books_need_product_to_publish
  validate :paid_books_need_seller
  validate :published_paid_books_require_seller_preference
  validate :published_paid_books_require_seller_ready_to_sell
  validate :price_currency_must_be_supported

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

  def tag_names
    tags.ordered.pluck(:name)
  end

  def assign_tags!(names)
    normalized = Array(names).flat_map { |name| name.to_s.split(",") }
      .map { |name| name.strip.downcase }
      .reject(&:blank?)
      .uniq

    self.tags = normalized.first(5).map do |name|
      Tag.find_or_create_by!(slug: name.parameterize) { |tag| tag.name = name }
    end
  end

  private
    def normalize_pricing
      if free?
        self.price_cents = nil
        self.price_currency = "USD"
      end
    end

    def paid_books_need_product_to_publish
      return unless published? && paid? && stripe_product_id.blank?

      errors.add(:published, "cannot be true for paid books without a Stripe product")
    end

    def paid_books_need_seller
      return unless paid?
      return if seller_user_id.present?

      errors.add(:seller_user, "must be present for paid books")
    end

    def published_paid_books_require_seller_ready_to_sell
      return unless paid? && published?
      return if seller_user&.can_sell_paid_books?

      errors.add(:published, "cannot be true for paid books until seller completes Stripe Connect onboarding")
    end

    def published_paid_books_require_seller_preference
      return unless paid? && published?
      return if seller_user&.sell_paid_books?

      errors.add(:published, "cannot be true for paid books until seller enables paid book sales")
    end

    def max_five_tags
      errors.add(:tags, "can have at most 5 tags") if tags.size > 5
    end

    def price_currency_must_be_supported
      return if price_currency.blank?
      return if Money::Currency.find(price_currency)

      errors.add(:price_currency, "is not supported")
    end

    def assign_default_category
      self.category ||= Category.find_or_create_by!(slug: "general") { |category| category.name = "General" }
    end
end
