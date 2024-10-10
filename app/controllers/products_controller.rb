class ProductsController < ApplicationController
  before_action :set_product, only: :show
  def index
    @pagy, @products = pagy(Product.all, limit: Settings.page_size)
    @product_count = Product.count
  end

  def show
    @pagy, @reviews = pagy @product.reviews.includes(:user),
                           limit: Settings.ui.reviews_limit
    @reviews_count = @reviews.count
  end

  private
  def set_product
    @product = Product.find_by id: params[:id]
    return if @product

    flash[:danger] = t ".not_found"
    redirect_to root_path
  end
end
