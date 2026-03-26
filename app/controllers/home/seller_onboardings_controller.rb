class Home::SellerOnboardingsController < ApplicationController
  def show
    @user = Current.user
  end

  def update
    @user = Current.user
    selected = ActiveModel::Type::Boolean.new.cast(params.require(:user).permit(:sell_paid_books).fetch(:sell_paid_books))
    unless [ true, false ].include?(selected)
      redirect_to home_seller_onboarding_url, alert: "Select a valid option"
      return
    end

    @user.update!(sell_paid_books: selected)
    if @user.sell_paid_books?
      redirect_to home_billing_url, notice: "Great. Set up Stripe Connect to start selling paid books."
    else
      @user.update!(seller_attention_required: false, seller_attention_reason: nil, seller_attention_book_id: nil)
      redirect_to home_url, notice: "Free-only mode enabled. You can switch to paid anytime from onboarding or billing."
    end
  end
end
