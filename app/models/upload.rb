class Upload < ApplicationRecord
  PARSER_VERSION = "markdown-v2"

  belongs_to :api_key
  belongs_to :user
  belongs_to :book, optional: true

  has_one_attached :source_bundle, dependent: :purge_later
  has_many :book_revisions, dependent: :nullify

  enum :status, %w[received processing accepted failed].index_by(&:itself), default: :received

  validates :source_sha256, :parser_version, presence: true
end
