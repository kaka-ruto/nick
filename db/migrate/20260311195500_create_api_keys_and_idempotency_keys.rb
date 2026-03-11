class CreateApiKeysAndIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key_digest, null: false
      t.string :scopes, array: true, default: [], null: false
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_keys, :key_digest, unique: true
    add_index :api_keys, :revoked_at

    create_table :idempotency_keys do |t|
      t.references :api_key, null: false, foreign_key: true
      t.string :key, null: false
      t.string :request_fingerprint, null: false
      t.integer :response_status
      t.text :response_body

      t.timestamps
    end

    add_index :idempotency_keys, [ :api_key_id, :key ], unique: true
  end
end
