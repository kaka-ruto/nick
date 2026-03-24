class AddUploadMetadataAndRevisionDiffs < ActiveRecord::Migration[8.1]
  def change
    change_column_default :uploads, :status, from: "uploaded", to: "received"

    add_column :uploads, :book_uid, :string
    add_column :uploads, :base_revision_id, :integer
    add_column :uploads, :source_commit, :string
    add_column :uploads, :agent_run_id, :string
    add_column :uploads, :validation_errors, :jsonb, null: false, default: []
    add_column :uploads, :warnings, :jsonb, null: false, default: []
    add_column :uploads, :build_log, :text

    add_column :book_revisions, :diff_summary, :jsonb, null: false, default: {}

    add_index :uploads, :book_uid
    add_index :uploads, :base_revision_id
  end
end
