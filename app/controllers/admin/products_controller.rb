class Admin::ProductsController < Admin::AdminController
  include Pagy::Backend
  before_action :find_product, only: %i(show edit update destroy)

  def index
    direction = (params[:direction]&.to_sym if %i(asc
desc).include?(params[:direction]&.to_sym)) || :asc
    @pagy, @products = pagy(Product.filtered(params).sorted(params[:sort],
                                                            direction).distinct)
    @categories = Category.all.pluck(:name, :id)
  end

  def show; end

  def new
    @product = Product.new
    @categories = Category.all
  end

  def create
    @product = Product.new(product_params)
    ActiveRecord::Base.transaction do
      @product.save!
      flash[:success] = t("admin.products_admin.create.success")
      redirect_to admin_product_path(@product)
    rescue ActiveRecord::RecordInvalid => e
      handle_create_error(e)
    end
  end

  def edit; end

  def update
    ActiveRecord::Base.transaction do
      @product.update!(product_params)
      flash[:success] = t("admin.products_admin.update.success")
      redirect_to admin_product_path(@product)
    end
  rescue ActiveRecord::RecordInvalid => e
    handle_create_update_error(e)
  end

  def destroy
    ActiveRecord::Base.transaction do
      @product.destroy!
      flash[:success] = t("admin.products_admin.destroy.success")
      redirect_to admin_products_path
    rescue ActiveRecord::RecordNotDestroyed
      flash[:alert] = t("admin.products_admin.destroy.error")
      redirect_to admin_product_path(@product), status: :unprocessable_entity
    end
  end

  private

  def find_product
    @product = Product.find_by(id: params[:id])
    return if @product

    flash[:alert] = t(".not_found")
    redirect_to admin_products_path
  end

  def product_params
    params.require(:product).permit(Product::PRODUCT_ADMIN_ATTRIBUTES)
  end

  def handle_create_error error
    flash.now[:alert] =
      t("admin.products_admin.create.failure", error: error.message)
    render :new, status: :unprocessable_entity
  end

  def handle_update_error exception
    flash[:alert] = if exception.record == @order
                      t(
                        "admin.orders_admin.update.error_with_order",
                        errors: exception.record.errors.full_messages.join(", ")
                      )
                    else
                      t("admin.orders_admin.update.error_with_address")
                    end
    redirect_to edit_admin_order_path(@order), status: :unprocessable_entity
  end
end
