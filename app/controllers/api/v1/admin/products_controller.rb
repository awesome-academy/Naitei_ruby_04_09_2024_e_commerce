class Api::V1::Admin::ProductsController < Api::V1::ApplicationController
  before_action :authenticate_user!, :authenticate_admin!
  before_action :find_product, only: %i(show update destroy)

  def index
    @q = Product.ransack(params[:q] || {})
    @products_search = @q.result(distinct: true)

    render json: @products_search, each_serializer: ProductSerializer,
           status: :ok
  end

  def show
    render json: @product, serializer: ProductSerializer, status: :ok
  end

  def create
    @product = Product.new(product_params)
    @product.rating = 0

    if @product.save
      render json: {
        message: I18n.t("admin.products_admin.create.success"),
        product: ProductSerializer.new(@product)
      }, status: :created
    else
      render json: {errors: @product.errors.full_messages},
             status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      render json: {
        message: I18n.t("admin.products_admin.update.success"),
        product: ProductSerializer.new(@product)
      }, status: :ok
    else
      render json: {errors: @product.errors.full_messages},
             status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      render json: {message: I18n.t("admin.products_admin.destroy.success")},
             status: :ok
    else
      render json: {errors: I18n.t("admin.products_admin.destroy.error")},
             status: :unprocessable_entity
    end
  end

  private

  def product_params
    params.require(:product).permit(Product::PRODUCT_ADMIN_ATTRIBUTES)
  end

  def find_product
    @product = Product.find_by(id: params[:id])
    return if @product

    render json: {errors: I18n.t("products.show.not_found")}, status: :not_found
  end
end
