class CreateAgentsAndTransitionPrincipals < ActiveRecord::Migration[8.1]
  def up
    create_table :agents do |t|
      t.bigint :legacy_user_id
      t.references :owner_user, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :username, null: false
      t.string :slug, null: false
      t.datetime :claimed_at
      t.timestamps
    end

    add_index :agents, :username, unique: true
    add_index :agents, :slug, unique: true

    add_column :users, :username, :string
    add_column :users, :slug, :string
    add_index :users, :username, unique: true
    add_index :users, :slug, unique: true

    add_reference :api_keys, :agent, foreign_key: true

    execute <<~SQL
      UPDATE users
      SET username = lower(regexp_replace(split_part(email_address, '@', 1), '[^a-zA-Z0-9_]+', '-', 'g')),
          slug = lower(regexp_replace(split_part(email_address, '@', 1), '[^a-zA-Z0-9_]+', '-', 'g'))
      WHERE username IS NULL
    SQL

    execute <<~SQL
      INSERT INTO agents (legacy_user_id, owner_user_id, name, username, slug, claimed_at, created_at, updated_at)
      SELECT id, claimed_by_user_id, name, COALESCE(username, lower(regexp_replace(split_part(email_address, '@', 1), '[^a-zA-Z0-9_]+', '-', 'g'))), COALESCE(slug, lower(regexp_replace(split_part(email_address, '@', 1), '[^a-zA-Z0-9_]+', '-', 'g'))), claimed_at, created_at, updated_at
      FROM users
      WHERE agent = true
    SQL

    execute <<~SQL
      UPDATE api_keys
      SET agent_id = agents.id
      FROM agents
      WHERE agents.legacy_user_id = api_keys.user_id
    SQL

    add_reference :agent_claims, :agent_record, foreign_key: { to_table: :agents }

    execute <<~SQL
      UPDATE agent_claims
      SET agent_record_id = agents.id
      FROM agents
      WHERE agents.legacy_user_id = agent_claims.agent_id
    SQL

    remove_reference :agent_claims, :agent, foreign_key: { to_table: :users }
    rename_column :agent_claims, :agent_record_id, :agent_id

    execute "DELETE FROM users WHERE agent = true"

    remove_reference :users, :claimed_by_user, foreign_key: { to_table: :users }
    remove_column :users, :agent
    remove_column :users, :claimed_at
    remove_column :agents, :legacy_user_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
