class BookUnit < ApplicationRecord
  belongs_to :book
  belongs_to :leaf

  validates :external_id, :content_sha256, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :external_id, uniqueness: { scope: :book_id }
end
