class CreateApiKeyEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :api_key_events do |t|
      t.references :api_key, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :api_key_events, [ :api_key_id, :created_at ]
    add_index :api_key_events, [ :subject_type, :subject_id ]
  end
end
