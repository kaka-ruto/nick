class Home::BillingsController < ApplicationController
  def show
    @books = Book.accessable_or_published.where(pricing_type: :paid).ordered
    @merchant = Current.user.merchant_processor
    @merchant_account = @merchant&.account if @merchant&.processor_id.present?
    @sales = Current.user.book_sales_as_seller.includes(:book, :buyer_user).order(created_at: :desc).limit(25)
    @gross_cents = @sales.sum(&:gross_cents)
    @fees_cents = @sales.sum(&:stripe_fee_cents)
    @net_cents = @sales.sum(&:net_cents)
    @seller_cents = @sales.sum(&:seller_amount_cents)
    @platform_cents = @sales.sum(&:platform_amount_cents)
    @pending_payout_cents = @sales.select { |sale| sale.transferred_at.blank? }.sum(&:seller_amount_cents)
  end
end
