class BookView < ApplicationRecord
  WINDOW_DAYS = 30

  belongs_to :book
  belongs_to :user, optional: true

  validates :viewed_on, presence: true

  scope :recent, -> { where(viewed_on: WINDOW_DAYS.days.ago.to_date..) }

  def self.record!(book:, user:, visitor_id:, viewed_on: Date.current)
    attrs = {
      book_id: book.id,
      user_id: user&.id,
      visitor_id: visitor_id,
      viewed_on: viewed_on,
      created_at: Time.current,
      updated_at: Time.current
    }

    if user.present?
      upsert(attrs, unique_by: :index_book_views_on_book_date_user)
    elsif visitor_id.present?
      upsert(attrs, unique_by: :index_book_views_on_book_date_visitor)
    end
  end
end
