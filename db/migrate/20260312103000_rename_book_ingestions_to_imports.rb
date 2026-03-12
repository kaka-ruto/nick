class RenameBookIngestionsToImports < ActiveRecord::Migration[8.1]
  def up
    if table_exists?(:book_ingestions)
      rename_table :book_ingestions, :imports

      safe_rename_index :imports, :index_book_ingestions_on_api_key_id, :index_imports_on_api_key_id
      safe_rename_index :imports, :index_book_ingestions_on_book_id, :index_imports_on_book_id
      safe_rename_index :imports, :index_book_ingestions_on_status, :index_imports_on_status
      safe_rename_index :imports, :index_book_ingestions_on_user_id, :index_imports_on_user_id
    end

    if column_exists?(:books, :ingestion_revision)
      rename_column :books, :ingestion_revision, :import_revision
    end

    execute <<~SQL
      UPDATE active_storage_attachments
      SET record_type = 'Import'
      WHERE record_type = 'BookIngestion'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE active_storage_attachments
      SET record_type = 'BookIngestion'
      WHERE record_type = 'Import'
    SQL

    if column_exists?(:books, :import_revision)
      rename_column :books, :import_revision, :ingestion_revision
    end

    if table_exists?(:imports)
      safe_rename_index :imports, :index_imports_on_api_key_id, :index_book_ingestions_on_api_key_id
      safe_rename_index :imports, :index_imports_on_book_id, :index_book_ingestions_on_book_id
      safe_rename_index :imports, :index_imports_on_status, :index_book_ingestions_on_status
      safe_rename_index :imports, :index_imports_on_user_id, :index_book_ingestions_on_user_id

      rename_table :imports, :book_ingestions
    end
  end

  private
    def safe_rename_index(table, old_name, new_name)
      return unless index_name_exists?(table, old_name)
      return if index_name_exists?(table, new_name)

      rename_index table, old_name, new_name
    end
end
