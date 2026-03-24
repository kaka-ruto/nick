class AddUploadsAndBookRevisions < ActiveRecord::Migration[8.1]
  def up
    if table_exists?(:imports) && !table_exists?(:uploads)
      rename_table :imports, :uploads

      safe_rename_index :uploads, :index_imports_on_api_key_id, :index_uploads_on_api_key_id
      safe_rename_index :uploads, :index_imports_on_book_id, :index_uploads_on_book_id
      safe_rename_index :uploads, :index_imports_on_status, :index_uploads_on_status
      safe_rename_index :uploads, :index_imports_on_user_id, :index_uploads_on_user_id
    end

    execute <<~SQL
      UPDATE active_storage_attachments
      SET record_type = 'Upload'
      WHERE record_type = 'Import'
    SQL

    create_table :book_revisions do |t|
      t.references :book, null: false, foreign_key: true
      t.references :upload, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :source_sha256, null: false
      t.jsonb :metadata, null: false, default: {}
      t.jsonb :units, null: false, default: []
      t.timestamps
    end

    add_index :book_revisions, [ :book_id, :number ], unique: true

    add_column :books, :book_uid, :string
    add_reference :books, :current_draft_revision, foreign_key: { to_table: :book_revisions }, null: true
    add_reference :books, :published_revision, foreign_key: { to_table: :book_revisions }, null: true
    add_index :books, :book_uid, unique: true
  end

  def down
    remove_reference :books, :published_revision, foreign_key: { to_table: :book_revisions }
    remove_reference :books, :current_draft_revision, foreign_key: { to_table: :book_revisions }
    remove_index :books, :book_uid
    remove_column :books, :book_uid

    drop_table :book_revisions

    execute <<~SQL
      UPDATE active_storage_attachments
      SET record_type = 'Import'
      WHERE record_type = 'Upload'
    SQL

    if table_exists?(:uploads) && !table_exists?(:imports)
      safe_rename_index :uploads, :index_uploads_on_api_key_id, :index_imports_on_api_key_id
      safe_rename_index :uploads, :index_uploads_on_book_id, :index_imports_on_book_id
      safe_rename_index :uploads, :index_uploads_on_status, :index_imports_on_status
      safe_rename_index :uploads, :index_uploads_on_user_id, :index_imports_on_user_id

      rename_table :uploads, :imports
    end
  end

  private
    def safe_rename_index(table, old_name, new_name)
      return unless index_name_exists?(table, old_name)
      return if index_name_exists?(table, new_name)

      rename_index table, old_name, new_name
    end
end
