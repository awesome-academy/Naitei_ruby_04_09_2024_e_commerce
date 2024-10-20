class ReviewsController < ApplicationController
  before_action :find_user, :logged_in_user
  load_and_authorize_resource :order
  load_and_authorize_resource :product, through: :order
  load_and_authorize_resource :review, through: :product, except: %i(new create)
  before_action :check_order_delivered,
                only: %i(new create edit update destroy)

  before_action :check_review, only: %i(new create)

  def new
    @review = @product.reviews.build
  end

  def create
    @review = @product.reviews.build(review_params)
    @review.user = current_user
    @review.order = @order
    if @review.save
      @product.update_average_rating
      flash[:success] = t "reviews.success"
      redirect_to user_order_order_details_path(current_user, @order)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @review.update(review_params)
      @product.update_average_rating
      flash[:success] = t "reviews.updated"
      redirect_to user_order_order_details_path(current_user, @order)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    @product.update_average_rating
    flash[:success] = t "reviews.destroyed"
    redirect_to user_order_order_details_path(current_user, @order)
  end

  private

  def check_order_delivered
    return if @order&.delivered?

    flash[:danger] = t("reviews.must_be_delivered")
    redirect_to root_path
  end

  def find_review
    @review = @product.reviews.find_by id: params[:id]
    return if @review

    flash[:danger] = t "reviews.review_not_exist"
    redirect_to root_path
  end

  def find_order
    @order = current_user.orders.find_by id: params[:order_id]
    return if @order

    flash[:danger] = t "reviews.order_not_exist"
    redirect_to root_path
  end

  def find_product
    @order_item = @order.order_items.find_by(product_id: params[:product_id])
    @product = @order_item&.product

    return if @product.present?

    flash[:danger] = t "reviews.product_not_exist"
    redirect_to root_path
  end

  def check_review
    existing_review = @product.reviews.find_by(user_id: current_user.id,
                                               order_id: @order.id)

    return if existing_review.blank?

    flash[:danger] = t "reviews.already_reviewed"
    redirect_to root_path
  end

  def review_params
    params.require(:review).permit Review::REVIEW_REQUIRE_ATTRIBUTES
  end

  def find_user
    @user = User.find_by(id: params[:user_id])

    return if @user.present?

    flash[:danger] = t "reviews.user_not_exist"
    redirect_to root_path
  end
end
