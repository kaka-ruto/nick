class BookSale < ApplicationRecord
  SELLER_SHARE_NUMERATOR = 85
  SELLER_SHARE_DENOMINATOR = 100

  belongs_to :book
  belongs_to :buyer_user, class_name: "User"
  belongs_to :seller_user, class_name: "User"
  belongs_to :pay_charge, class_name: "Pay::Charge"

  validates :currency, presence: true
  validates :gross_cents, :stripe_fee_cents, :net_cents, :seller_amount_cents, :platform_amount_cents, presence: true
  validates :pay_charge_id, uniqueness: true

  scope :transferred, -> { where.not(transferred_at: nil) }
  scope :pending_transfer, -> { where(transferred_at: nil) }

  def self.seller_amount_for_net(net_cents)
    (net_cents.to_i * SELLER_SHARE_NUMERATOR) / SELLER_SHARE_DENOMINATOR
  end
end
