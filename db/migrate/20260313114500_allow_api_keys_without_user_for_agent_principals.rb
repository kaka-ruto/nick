class AllowApiKeysWithoutUserForAgentPrincipals < ActiveRecord::Migration[8.1]
  def change
    change_column_null :api_keys, :user_id, true
  end
end
