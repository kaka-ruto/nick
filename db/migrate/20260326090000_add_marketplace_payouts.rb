class AddMarketplacePayouts < ActiveRecord::Migration[8.1]
  def change
    add_reference :books, :seller_user, foreign_key: { to_table: :users }, index: true

    add_column :users, :stripe_connect_account_id, :string
    add_column :users, :stripe_connect_details_submitted, :boolean, default: false, null: false
    add_column :users, :stripe_connect_charges_enabled, :boolean, default: false, null: false
    add_column :users, :stripe_connect_payouts_enabled, :boolean, default: false, null: false
    add_index :users, :stripe_connect_account_id, unique: true

    create_table :book_sales do |t|
      t.references :book, null: false, foreign_key: true
      t.references :buyer_user, null: false, foreign_key: { to_table: :users }
      t.references :seller_user, null: false, foreign_key: { to_table: :users }
      t.references :pay_charge, null: false, foreign_key: true, index: { unique: true }
      t.string :currency, null: false
      t.integer :gross_cents, null: false
      t.integer :stripe_fee_cents, null: false
      t.integer :net_cents, null: false
      t.integer :seller_amount_cents, null: false
      t.integer :platform_amount_cents, null: false
      t.string :stripe_transfer_id
      t.datetime :transferred_at
      t.timestamps
    end

    add_index :book_sales, :stripe_transfer_id, unique: true
  end
end
