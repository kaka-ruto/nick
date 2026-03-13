class CreateAgentClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_claims do |t|
      t.references :agent, null: false, foreign_key: { to_table: :users }
      t.references :claimed_by_user, foreign_key: { to_table: :users }
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :claimed_at
      t.timestamps
    end

    add_index :agent_claims, :token_digest, unique: true
    add_index :agent_claims, [ :agent_id, :claimed_at ]
  end
end
