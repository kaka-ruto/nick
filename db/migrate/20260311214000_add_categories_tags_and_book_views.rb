class AddCategoriesTagsAndBookViews < ActiveRecord::Migration[8.1]
  def up
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true

    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :tags, :name, unique: true
    add_index :tags, :slug, unique: true

    create_table :book_tags do |t|
      t.references :book, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :book_tags, [ :book_id, :tag_id ], unique: true

    create_table :book_views do |t|
      t.references :book, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :visitor_id
      t.date :viewed_on, null: false

      t.timestamps
    end

    add_index :book_views, [ :book_id, :viewed_on, :user_id ], unique: true, where: "user_id IS NOT NULL", name: "index_book_views_on_book_date_user"
    add_index :book_views, [ :book_id, :viewed_on, :visitor_id ], unique: true, where: "visitor_id IS NOT NULL", name: "index_book_views_on_book_date_visitor"

    add_reference :books, :category, null: true, foreign_key: true

    execute "INSERT INTO categories (name, slug, created_at, updated_at) VALUES ('General', 'general', NOW(), NOW())"
    general_id = select_value("SELECT id FROM categories WHERE slug = 'general'").to_i
    execute <<~SQL
      UPDATE books
      SET category_id = #{general_id}
      WHERE category_id IS NULL
    SQL

    change_column_null :books, :category_id, false
  end

  def down
    remove_reference :books, :category, foreign_key: true

    drop_table :book_views
    drop_table :book_tags
    drop_table :tags
    drop_table :categories
  end
end
