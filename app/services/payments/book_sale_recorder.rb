module Payments
  class BookSaleRecorder
    def self.call(charge_id:)
      new(charge_id:).call
    end

    def initialize(charge_id:)
      @charge_id = charge_id
    end

    def call
      charge = Pay::Charge.find_by(processor_id: @charge_id)
      return if charge.blank?

      metadata = charge.metadata || {}
      book = Book.find_by(id: metadata["book_id"])
      buyer = User.find_by(id: metadata["user_id"])
      return if book.blank? || buyer.blank? || book.seller_user.blank?

      stripe_charge = Stripe::Charge.retrieve(@charge_id, { expand: [ "balance_transaction" ] })
      balance = stripe_charge.balance_transaction
      return if balance.blank?

      gross_cents = balance.amount.to_i
      stripe_fee_cents = balance.fee.to_i
      net_cents = balance.net.to_i
      seller_amount_cents = BookSale.seller_amount_for_net(net_cents)
      platform_amount_cents = net_cents - seller_amount_cents

      BookSale.transaction do
        sale = BookSale.find_or_initialize_by(pay_charge: charge)
        sale.assign_attributes(
          book: book,
          buyer_user: buyer,
          seller_user: book.seller_user,
          currency: (balance.currency || stripe_charge.currency || "usd").to_s.downcase,
          gross_cents: gross_cents,
          stripe_fee_cents: stripe_fee_cents,
          net_cents: net_cents,
          seller_amount_cents: seller_amount_cents,
          platform_amount_cents: platform_amount_cents
        )
        sale.save!
        sale
      end
    end
  end
end
