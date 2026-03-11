class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :set_book, only: %i[ show edit update destroy ]
  before_action :set_users, :set_categories, only: %i[ new edit ]
  before_action :ensure_editable, only: %i[ edit update destroy ]

  def index
    books = Book.accessable_or_published
    books = books.where(category_id: params[:category_id]) if params[:category_id].present?
    books = books.left_outer_joins(:tags).where(
      "books.title ILIKE :q OR books.subtitle ILIKE :q OR books.author ILIKE :q OR tags.name ILIKE :q",
      q: "%#{params[:q]}%"
    ).distinct if params[:q].present?

    @books = books.ordered
    @popular_books = Book.published.popular.limit(6)
    @featured_book = @popular_books.first || @books.first
    @categories = Category.ordered
  end

  def new
    @book = Book.new
  end

  def create
    book = Book.create! book_params
    book.assign_tags!(tag_names)
    update_accesses(book)

    redirect_to book_slug_url(book)
  end

  def show
    @can_read = @book.readable_by?
    @leaves = @can_read ? @book.leaves.active.with_leafables.positioned : []
    record_view if @can_read
  end

  def edit
  end

  def update
    @book.update(book_params)
    @book.assign_tags!(tag_names)
    update_accesses(@book)
    remove_cover if params[:remove_cover] == "true"

    redirect_to book_slug_url(@book)
  end

  def destroy
    @book.destroy

    redirect_to root_url
  end

  private
    def set_book
      @book = Book.accessable_or_published.find params[:id]
    end

    def set_users
      @users = User.active.ordered
    end

    def ensure_editable
      head :forbidden unless @book.editable?
    end

    def book_params
      params.require(:book).permit(:title, :subtitle, :author, :cover, :remove_cover, :everyone_access, :theme, :pricing_type, :price_cents, :category_id)
    end

    def tag_names
      params.dig(:book, :tag_names)
    end

    def update_accesses(book)
      editors = [ Current.user.id, *params[:editor_ids]&.map(&:to_i) ]
      readers = [ Current.user.id, *params[:reader_ids]&.map(&:to_i) ]

      book.update_access(editors: editors, readers: readers)
    end

    def remove_cover
      @book.cover.purge
    end

    def set_categories
      @categories = Category.ordered
    end

    def record_view
      BookView.record!(book: @book, user: Current.user, visitor_id: visitor_id)
    end

    def visitor_id
      cookies.signed[:visitor_id] ||= SecureRandom.uuid
    end
end
