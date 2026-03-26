class Books::PurchasesController < ApplicationController
  include BookScoped

  allow_unauthenticated_access only: :success

  def create
    if @book.free_pricing_type?
      @book.grant_reader_access(Current.user)
      redirect_to book_slug_url(@book)
      return
    end

    checkout_session = Current.user.payment_processor.checkout_charge(
      amount: @book.price_cents,
      currency: @book.price_currency.to_s.downcase,
      name: @book.title,
      success_url: success_book_purchase_url(@book),
      cancel_url: book_slug_url(@book),
      metadata: {
        book_id: @book.id,
        user_id: Current.user.id,
        seller_user_id: @book.seller_user_id,
        split_model: "net_85_15"
      }
    )

    redirect_to checkout_session.url, allow_other_host: true
  end

  def success
    return redirect_to new_session_url unless signed_in?

    Pay.sync(params)

    if @book.free_pricing_type?
      @book.grant_reader_access(Current.user)
      redirect_to book_slug_url(@book)
      return
    end

    has_purchase = Current.user.pay_charges.where("metadata ->> 'book_id' = ?", @book.id.to_s).exists?
    if has_purchase
      @book.grant_reader_access(Current.user)
    end

    redirect_to book_slug_url(@book)
  end
end
