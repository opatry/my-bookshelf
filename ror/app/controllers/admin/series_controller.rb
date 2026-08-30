module Admin
  class SeriesController < BaseController
    before_action :set_series, only: %i[edit update destroy]

    def index
      @series_list = Series.order(:name).includes(:books)
    end

    def new
      @series = Series.new
    end

    def create
      @series = Series.new(series_params)
      if @series.save
        redirect_to admin_series_index_path, notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @series.update(series_params)
        redirect_to admin_series_index_path, notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @series.destroy
      redirect_to admin_series_index_path, notice: t(".success")
    end

    private

    def set_series
      @series = Series.find(params[:id])
    end

    def series_params
      params.require(:series).permit(:name)
    end
  end
end
