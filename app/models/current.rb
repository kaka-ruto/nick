class Current < ActiveSupport::CurrentAttributes
  attribute :user, :api_key

  def account
    Account.first
  end
end
