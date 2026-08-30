module Admin
  class TagsController < BaseController
    before_action :set_tag, only: %i[edit update destroy]

    def index
      @tags = Tag.order(:name)
    end

    def new
      @tag = Tag.new
    end

    def create
      @tag = Tag.new(tag_params)
      if @tag.save
        redirect_to admin_tags_path, notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tag.update(tag_params)
        redirect_to admin_tags_path, notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tag.destroy
      redirect_to admin_tags_path, notice: t(".success")
    end

    private

    def set_tag
      # Admin links are built through Tag#to_param (slug); accept both forms.
      @tag = Tag.find_by(id: params[:id].to_i) || Tag.find_by!(slug: params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
