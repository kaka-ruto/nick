class Tag < ApplicationRecord
  has_many :book_tags, dependent: :destroy
  has_many :books, through: :book_tags

  validates :name, :slug, presence: true
  validates :name, :slug, uniqueness: true

  scope :ordered, -> { order(:name) }
end
