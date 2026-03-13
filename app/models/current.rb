class Current < ActiveSupport::CurrentAttributes
  attribute :user, :agent, :api_key

  def account
    Account.first
  end
end
