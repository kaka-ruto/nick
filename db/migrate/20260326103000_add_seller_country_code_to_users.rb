class AddSellerCountryCodeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :seller_country_code, :string
    add_index :users, :seller_country_code
  end
end
