class CreateLeafSearchIndexTable < ActiveRecord::Migration[8.0]
  def change
    return if table_exists?(:leaf_search_index)

    create_table :leaf_search_index, id: false do |t|
      t.bigint :rowid, null: false, primary_key: true
      t.text :title
      t.text :content
    end

    add_index :leaf_search_index, :rowid, unique: true

    Leaf.reindex_all
  end
end
