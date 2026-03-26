require "test_helper"

class Payments::BookSaleRecorderTest < ActiveSupport::TestCase
  test "records sale with 85/15 split on net receipts" do
    buyer = users(:kevin)
    seller = users(:david)
    seller.update!(sell_paid_books: true)
    seller.set_merchant_processor(:stripe, processor_id: "acct_ready", onboarding_complete: true)
    book = books(:handbook)
    book.update!(seller_user: seller, pricing_type: :paid, price_cents: 1000, stripe_product_id: "prod_123")

    customer = Pay::Customer.create!(owner: buyer, processor: "stripe", processor_id: "cus_123", default: true, type: "Pay::Stripe::Customer")
    charge = Pay::Charge.create!(
      customer: customer,
      processor_id: "ch_123",
      amount: 1000,
      currency: "usd",
      metadata: { "book_id" => book.id, "user_id" => buyer.id },
      type: "Pay::Stripe::Charge"
    )

    balance = Struct.new(:amount, :fee, :net, :currency).new(1000, 59, 941, "usd")
    stripe_charge = Struct.new(:balance_transaction, :currency).new(balance, "usd")

    Stripe::Charge.stubs(:retrieve).returns(stripe_charge)

    sale = Payments::BookSaleRecorder.call(charge_id: charge.processor_id)
    assert sale.persisted?
    assert_equal book, sale.book
    assert_equal buyer, sale.buyer_user
    assert_equal seller, sale.seller_user
    assert_equal 941, sale.net_cents
    assert_equal 799, sale.seller_amount_cents
    assert_equal 142, sale.platform_amount_cents
  end
end
