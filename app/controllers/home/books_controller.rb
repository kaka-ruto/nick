class Home::BooksController < ApplicationController
  def index
    @books = Book.accessable_or_published.ordered
  end

  def show
    @book = Book.accessable_or_published.find(params[:id])
    @revisions = @book.book_revisions.order(number: :desc).limit(20)
    @uploads = @book.uploads.order(created_at: :desc).limit(10)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
