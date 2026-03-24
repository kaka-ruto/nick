class Book < ApplicationRecord
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
  has_one_attached :cover, dependent: :purge_later

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

  before_validation :normalize_pricing
  before_validation :assign_default_category

  validates :price_cents, numericality: { greater_than: 0, only_integer: true }, if: :paid?
  validates :price_cents, absence: true, if: :free?
  validates :category, presence: true
  validate :max_five_tags
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
      self.price_cents = nil if free?
    end

    def paid_books_need_product_to_publish
      return unless published? && paid? && stripe_product_id.blank?

      errors.add(:published, "cannot be true for paid books without a Stripe product")
    end

    def max_five_tags
      errors.add(:tags, "can have at most 5 tags") if tags.size > 5
    end

    def assign_default_category
      self.category ||= Category.find_or_create_by!(slug: "general") { |category| category.name = "General" }
    end
end
