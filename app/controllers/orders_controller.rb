class OrdersController < ApplicationController
  before_action :set_cart_items, only: [:new, :create]
  before_action :set_order, only: [:show]
  before_action :set_user, :correct_user, :logged_in_user,
                only: %i(order_details index cancel)
  before_action :set_order_details, only: %i(order_details)
  before_action :set_order_cancel, only: %i(cancel)

  def new
    @order = Order.new
    @order.total = calculate_cart_total
  end

  def create
    @order = Order.new(order_params)
    @order.user = current_user
    @order.total = calculate_cart_total

    if @order.save
      save_order_items(@order)
      clear_cart
      current_user.send_order_confirm_email @order
      redirect_to order_path(@order)
    else
      flash.now[:alert] = t ".order_fail"
      render :new
    end
  end

  def index
    @orders = @user.orders.with_status(params[:status])

    @pagy, @orders = pagy(
      @orders.ordered_by_updated_at.includes(:address, order_items: :product),
      limit: Settings.ui.address_limit
    )
  end

  def order_details
    render "orders/_order_details"
  end

  def show; end

  def cancel
    cancel_reason = params.dig(:order, :cancel_reason)
    if @order.pending?
      if cancel_reason.present? && @order.update(cancel_reason:,
                                                 status: "cancelled")
        update_cart_items @order
        flash[:success] = t ".order_canceled"
      else
        flash[:danger] = t ".cancel_failed"
      end
    else
      flash[:danger] = t ".cannot_cancel_order"
    end
    redirect_to user_order_order_details_path(@user, @order)
  end

  private
  def set_cart_items
    @cart_items = current_cart_items
  end

  def current_cart_items
    current_user.cart.cart_items.includes(product: :category)
  end

  def set_order
    @order = Order.find_by(id: params[:id])
    return if @order

    flash[:alert] = t ".order_not_found"
    redirect_to root_path
  end

  def order_params
    params.require(:order).permit(
      Order::UPDATE_ORDER
    )
  end

  def calculate_cart_total
    @cart_items.sum{|item| item.product.price * item.quantity}
  end

  def save_order_items order
    @cart_items.each do |item|
      order.order_items.create(product_id: item.product_id,
                               price: item.product.price,
                               quantity: item.quantity)
      if item.product.stock >= item.quantity
        item.product.decrement!(:stock,
                                item.quantity)
      end
    end
  end

  def clear_cart
    current_user.cart.cart_items.destroy_all
  end

  def set_user
    @user = User.find_by id: params[:user_id]
    return if @user

    flash[:danger] = t ".not_found"
    redirect_to root_path
  end

  def set_order_details
    @order = @user.orders
                  .includes(:address, order_items: :product)
                  .find_by(id: params[:order_id])
    return @order_items = @order.order_items.includes(:product) if @order

    flash[:danger] = t ".not_found_order"
    redirect_to root_path
  end

  def set_order_cancel
    @order = @user.orders
                  .includes(:address, order_items: :product)
                  .find_by(id: params[:id])
    return @order_items = @order.order_items.includes(:product) if @order

    flash[:danger] = t ".not_found_order"
    redirect_to root_path
  end

  def update_cart_items order
    cart = current_user.cart || current_user.create_cart
    order.order_items.each do |order_item|
      cart_item = cart.cart_items.find_by(product_id: order_item.product_id)

      if cart_item
        increment_cart_item_quantity(cart_item, order_item)
      else
        create_new_cart_item(cart, order_item)
      end
      @product = Product.find order_item.product_id
      @product.increment! :stock, order_item.quantity
      current_user.send_order_cancel_email @order
    end
  end

  def increment_cart_item_quantity cart_item, order_item
    cart_item.quantity += order_item.quantity
    cart_item.save
  end

  def create_new_cart_item cart, order_item
    cart.cart_items.create!(
      product_id: order_item.product_id, quantity: order_item.quantity
    )
  end
end
