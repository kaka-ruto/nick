class ReplaceSellingPreferenceWithBoolean < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :sell_paid_books, :boolean
    add_index :users, :sell_paid_books

    execute <<~SQL
      UPDATE users
      SET sell_paid_books = CASE
        WHEN selling_preference = 'sell_paid_books' THEN TRUE
        WHEN selling_preference = 'free_only' THEN FALSE
        ELSE NULL
      END
    SQL

    remove_index :users, :selling_preference if index_exists?(:users, :selling_preference)
    remove_column :users, :selling_preference
  end

  def down
    add_column :users, :selling_preference, :string
    add_index :users, :selling_preference

    execute <<~SQL
      UPDATE users
      SET selling_preference = CASE
        WHEN sell_paid_books = TRUE THEN 'sell_paid_books'
        WHEN sell_paid_books = FALSE THEN 'free_only'
        ELSE NULL
      END
    SQL

    remove_index :users, :sell_paid_books if index_exists?(:users, :sell_paid_books)
    remove_column :users, :sell_paid_books
  end
end
