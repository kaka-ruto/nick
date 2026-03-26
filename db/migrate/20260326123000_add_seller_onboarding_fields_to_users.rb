class AddSellerOnboardingFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :selling_preference, :string
    add_column :users, :seller_attention_required, :boolean, default: false, null: false
    add_column :users, :seller_attention_reason, :string
    add_reference :users, :seller_attention_book, foreign_key: { to_table: :books }
    add_index :users, :selling_preference
  end
end
