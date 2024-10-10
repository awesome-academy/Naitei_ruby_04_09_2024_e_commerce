class Admin::CategoriesController < Admin::AdminController
  include Pagy::Backend
  before_action :find_category, only: %i(show edit update destroy)

  def index
    @pagy, @categories = pagy Category.sort_by_params(params)
  end

  def show; end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    begin
      @category.save!
      flash[:success] = t "admin.categories_admin.create.success"
      redirect_to admin_category_path(@category)
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = t "admin.categories_admin.create.failure"
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @category.update!(category_params)
    flash[:success] = t "admin.categories_admin.update.success"
    redirect_to admin_category_path(@category)
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = t "admin.categories_admin.update.failure"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @category.products.any?
        flash.now[:alert] = t "admin.categories_admin.destroy.has_products"
        render :edit, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      else
        destroy_category
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed
    handle_destroy_error
  end

  private

  def find_category
    @category = Category.find_by(id: params[:id])
    return if @category

    flash[:alert] = t "admin.categories_admin.not_found"
    redirect_to admin_categories_path
  end

  def category_params
    params.require(:category).permit(Category::CATEGORY_ADMIN_ATTRIBUTES)
  end

  def destroy_category
    @category.destroy!
    flash[:success] = t "admin.categories_admin.destroy.success"
    redirect_to admin_categories_path
  end

  def handle_destroy_error
    flash[:alert] = t "admin.categories_admin.destroy.failure"
    redirect_to admin_categories_path
  end
end
