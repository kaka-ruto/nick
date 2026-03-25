class Home::PricingsController < ApplicationController
  def show
    @books = Book.accessable_or_published.ordered
  end
end
