module Admin
  class ReviewsController < BaseController
    before_action :set_book
    before_action :set_review, only: %i[edit update destroy]

    def new
      if (existing = owner.reviews.find_by(book: @book))
        redirect_to edit_admin_book_review_path(@book, existing)
        return
      end
      @review = owner.reviews.build(book: @book)
    end

    def create
      @review = owner.reviews.build(review_params.merge(book: @book))
      if @review.save
        redirect_to admin_book_path(@book), notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @review.update(review_params)
        redirect_to admin_book_path(@book), notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @review.destroy
      redirect_to admin_book_path(@book), notice: t(".success")
    end

    private

    def set_book
      @book = Book.find(params[:book_id])
    end

    def set_review
      @review = owner.reviews.find_by!(book: @book)
    end

    def review_params
      params.require(:review).permit(:status, :rating, :read_date, :priority, :favorite)
    end
  end
end
