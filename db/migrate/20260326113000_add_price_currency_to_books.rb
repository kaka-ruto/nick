class AddPriceCurrencyToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :price_currency, :string, null: false, default: "USD"
    add_index :books, :price_currency
  end
end
