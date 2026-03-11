class ApiKeyEvent < ApplicationRecord
  belongs_to :api_key
  belongs_to :user

  validates :action, :subject_type, :subject_id, presence: true
end
