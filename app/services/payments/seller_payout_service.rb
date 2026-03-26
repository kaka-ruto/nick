module Payments
  class SellerPayoutService
    def self.call(book_sale:)
      new(book_sale:).call
    end

    def initialize(book_sale:)
      @book_sale = book_sale
    end

    def call
      return @book_sale if @book_sale.transferred_at.present?
      return @book_sale unless @book_sale.seller_user.stripe_connect_ready?
      return @book_sale if @book_sale.seller_amount_cents <= 0

      transfer = @book_sale.seller_user.merchant_processor.transfer(
        amount: @book_sale.seller_amount_cents,
        currency: @book_sale.currency,
        source_transaction: @book_sale.pay_charge.processor_id,
        metadata: {
          book_sale_id: @book_sale.id,
          book_id: @book_sale.book_id,
          seller_user_id: @book_sale.seller_user_id
        }
      )

      @book_sale.update!(
        stripe_transfer_id: transfer.id,
        transferred_at: Time.current
      )
      @book_sale
    rescue Pay::Stripe::Error => e
      Rails.logger.warn("seller payout skipped for book_sale=#{@book_sale.id}: #{e.message}")
      @book_sale
    end
  end
end
