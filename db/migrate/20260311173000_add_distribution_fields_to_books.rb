class AddDistributionFieldsToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :pricing_type, :string, null: false, default: "free"
    add_column :books, :price_cents, :integer
    add_column :books, :stripe_product_id, :string

    add_index :books, :pricing_type
    add_index :books, :stripe_product_id
  end
end
