class Books::PublicationsController < ApplicationController
  include BookScoped

  before_action :ensure_editable, only: %i[ edit update ]

  def show
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to book_slug_url(@book)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def book_params
      params.require(:book).permit(:published)
    end
end
