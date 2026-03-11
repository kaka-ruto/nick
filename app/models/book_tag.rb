class BookTag < ApplicationRecord
  belongs_to :book
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :book_id }
end
