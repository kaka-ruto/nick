class Home::PublishingsController < ApplicationController
  def show
    @books = Book.accessable_or_published.includes(:current_draft_revision, :published_revision).ordered
  end
end
