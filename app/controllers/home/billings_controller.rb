class Home::BillingsController < ApplicationController
  def show
    @books = Book.accessable_or_published.where(pricing_type: :paid).ordered
  end
end
