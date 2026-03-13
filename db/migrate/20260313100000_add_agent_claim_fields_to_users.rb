class AddAgentClaimFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :agent, :boolean, default: false, null: false
    add_column :users, :claimed_at, :datetime
    add_reference :users, :claimed_by_user, foreign_key: { to_table: :users }

    add_index :users, :agent
    add_index :users, :claimed_at
  end
end
