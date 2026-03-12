class Import < ApplicationRecord
  PARSER_VERSION = "markdown-v1"

  belongs_to :api_key
  belongs_to :user
  belongs_to :book, optional: true

  has_one_attached :source_file, dependent: :purge_later

  enum :status, %w[uploaded parsed applied failed].index_by(&:itself), default: :uploaded

  validates :source_sha256, :parser_version, presence: true
end
