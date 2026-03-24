class BookRevision < ApplicationRecord
  belongs_to :book
  belongs_to :upload

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :source_sha256, presence: true
  validates :number, uniqueness: { scope: :book_id }
end
