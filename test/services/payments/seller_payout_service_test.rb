require "test_helper"

class Payments::SellerPayoutServiceTest < ActiveSupport::TestCase
  test "creates transfer for payout-ready seller" do
    sale = create_sale!
    merchant = sale.seller_user.set_merchant_processor(:stripe, processor_id: "acct_123", onboarding_complete: true)

    transfer = Struct.new(:id).new("tr_123")
    merchant.stubs(:transfer).returns(transfer)
    Payments::SellerPayoutService.call(book_sale: sale)

    sale.reload
    assert_equal "tr_123", sale.stripe_transfer_id
    assert_not_nil sale.transferred_at
  end

  test "skips transfer when seller is not payout ready" do
    sale = create_sale!
    sale.seller_user.set_merchant_processor(:stripe, processor_id: "acct_123", onboarding_complete: false)

    sale.seller_user.merchant_processor.expects(:transfer).never
    Payments::SellerPayoutService.call(book_sale: sale)

    sale.reload
    assert_nil sale.stripe_transfer_id
    assert_nil sale.transferred_at
  end

  private
    def create_sale!
      buyer = users(:kevin)
      seller = users(:david)
      seller.update!(sell_paid_books: true)
      seller.set_merchant_processor(:stripe, processor_id: "acct_ready", onboarding_complete: true)
      book = books(:handbook)
      book.update!(seller_user: seller, pricing_type: :paid, price_cents: 1000, stripe_product_id: "prod_123")
      customer = Pay::Customer.create!(owner: buyer, processor: "stripe", processor_id: SecureRandom.hex(6), default: true, type: "Pay::Stripe::Customer")
      charge = Pay::Charge.create!(customer:, processor_id: "ch_#{SecureRandom.hex(6)}", amount: 1000, currency: "usd", type: "Pay::Stripe::Charge")

      BookSale.create!(
        book: book,
        buyer_user: buyer,
        seller_user: seller,
        pay_charge: charge,
        currency: "usd",
        gross_cents: 1000,
        stripe_fee_cents: 59,
        net_cents: 941,
        seller_amount_cents: 799,
        platform_amount_cents: 142
      )
    end
end
