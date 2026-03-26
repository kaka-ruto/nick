class Home::StripeConnectAccountsController < ApplicationController
  def create
    Current.user.update!(sell_paid_books: true) if Current.user.sell_paid_books != true
    merchant = ensure_connect_account!
    refresh_connect_status!(merchant)

    account_link = merchant.account_link(
      type: "account_onboarding",
      refresh_url: home_billing_url,
      return_url: home_billing_url
    )

    redirect_to account_link.url, allow_other_host: true
  rescue Pay::Stripe::Error => e
    redirect_to home_billing_url, alert: "Stripe Connect setup failed: #{e.message}"
  end

  def sync
    Current.user.update!(sell_paid_books: true) if Current.user.sell_paid_books != true
    refresh_connect_status!
    Current.user.book_sales_as_seller.pending_transfer.find_each do |sale|
      Payments::SellerPayoutService.call(book_sale: sale)
    end
    redirect_to home_billing_url
  rescue Pay::Stripe::Error => e
    redirect_to home_billing_url, alert: "Stripe Connect sync failed: #{e.message}"
  end

  private
    def ensure_connect_account!
      merchant = Current.user.merchant_processor || Current.user.set_merchant_processor(:stripe)
      return merchant if merchant.processor_id.present?

      country = normalized_country_code
      if ISO3166::Country[country].blank?
        raise Pay::Stripe::Error, "Unsupported country code: #{country}"
      end
      Current.user.update!(seller_country_code: country)

      merchant.create_account(
        type: "express",
        country: country,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true }
        },
        metadata: { user_id: Current.user.id }
      )
      merchant
    end

    def refresh_connect_status!(merchant = Current.user.merchant_processor)
      return if merchant.blank? || merchant.processor_id.blank?

      account = merchant.account
      merchant.update!(
        onboarding_complete: account.charges_enabled
      )
    end

    def normalized_country_code
      code = params[:country_code].presence || Current.user.seller_country_code.presence || "US"
      code.to_s.upcase
    end
end
