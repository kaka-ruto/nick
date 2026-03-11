class Category < ApplicationRecord
  has_many :books, dependent: :restrict_with_exception

  validates :name, :slug, presence: true
  validates :name, :slug, uniqueness: true

  scope :ordered, -> { order(:name) }
end
