class AddBookIngestionsAndUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :book_ingestions do |t|
      t.references :api_key, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :book, foreign_key: true
      t.string :status, null: false, default: "uploaded"
      t.string :source_sha256, null: false
      t.string :parser_version, null: false
      t.integer :expected_revision
      t.text :error_message
      t.datetime :applied_at
      t.jsonb :plan, null: false, default: {}
      t.jsonb :result, null: false, default: {}

      t.timestamps
    end

    add_index :book_ingestions, :status

    create_table :book_units do |t|
      t.references :book, null: false, foreign_key: true
      t.references :leaf, null: false, foreign_key: true
      t.string :external_id, null: false
      t.integer :position, null: false
      t.string :content_sha256, null: false

      t.timestamps
    end

    add_index :book_units, [ :book_id, :external_id ], unique: true

    add_column :books, :ingestion_revision, :integer, null: false, default: 0
  end
end
