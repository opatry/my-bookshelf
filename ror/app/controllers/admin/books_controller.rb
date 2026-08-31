module Admin
  class BooksController < BaseController
    before_action :set_book, only: %i[show edit update destroy]

    def index
      @books = Book.includes(:series, :tags, :reviews).order(:title)
    end

    def show
      @review = owner.reviews.find_by(book: @book)
    end

    def new
      @book = Book.new
    end

    def create
      @book = Book.new(book_params)
      @book.tags_from_names!
      if @book.save
        redirect_to admin_book_path(@book), notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @book.cover.purge if remove_cover? && params.dig(:book, :cover).present?
      @book.assign_attributes(book_params)
      @book.tags_from_names!
      if @book.save
        redirect_to admin_book_path(@book), notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @book.destroy
      redirect_to admin_books_path, notice: t(".success")
    end

    private

    def set_book
      @book = Book.includes(:tags).find(params[:id])
    end

    def book_params
      params.require(:book).permit(:title, :author, :isbn, :page_count, :publication_year,
                                   :description, :series_id, :cover, :tag_names, :remove_cover)
                                   .tap { |p| p.delete(:remove_cover) if p.key?(:remove_cover) }
    end

    # The `remove_cover` checkbox is a virtual form flag, not a Book attribute.
    # The Rails check_box helper always submits it (hidden "0" even when
    # unchecked), so it must be read separately and excluded from mass assignment.
    def remove_cover?
      ActiveModel::Type::Boolean.new.cast(params.dig(:book, :remove_cover))
    end
  end
end
