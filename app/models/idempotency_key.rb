class IdempotencyKey < ApplicationRecord
  belongs_to :api_key

  validates :key, presence: true, uniqueness: { scope: :api_key_id }
  validates :request_fingerprint, presence: true
end
