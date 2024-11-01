class Api::V1::OrdersController < Api::V1::ApplicationController
  before_action :authenticate_user!
  before_action :load_cart_items, only: [:create]
  before_action :find_order, only: [:show, :cancel]
  before_action :load_user, :correct_user, only: [:index, :cancel]

  def index
    @orders = @user.orders.with_status(params[:status]).order(id: :asc)
    render json: @orders, each_serializer: OrderSerializer, status: :ok
  end

  def show
    render json: @order, status: :ok
  end

  def create
    @order = Order.new(order_params)
    @order.user = current_user
    @order.total = calculate_cart_total

    if @order.save
      save_order_items(@order)
      clear_cart
      render json: @order, status: :created
    else
      Rails.logger.debug("Order errors: #{@order.errors.full_messages}")
      render json: {error: I18n.t("orders.create_failed")},
             status: :unprocessable_entity
    end
  end

  def cancel
    cancel_reason = params.dig(:order, :cancel_reason)

    if @order.pending? && cancel_reason.present?
      @order.update(cancel_reason:, status: "cancelled")
      update_cart_items(@order)
      render json: @order, status: :ok
    else
      render json: {error: I18n.t("orders.cancel_failed")},
             status: :unprocessable_entity
    end
  end

  private

  def load_cart_items
    @cart_items = current_cart_items
  end

  def current_cart_items
    current_user.cart.cart_items.includes(product: :category)
  end

  def find_order
    @order = Order.find_by(id: params[:id])
    return if @order

    render json: {error: I18n.t("orders.not_found")}, status: :not_found
  end

  def order_params
    params.require(:order).permit(:address_id, :payment_method)
  end

  def calculate_cart_total
    @cart_items.sum{|item| item.product.price * item.quantity}
  end

  def save_order_items order
    @cart_items.each do |item|
      order.order_items.create(
        product_id: item.product_id,
        price: item.product.price,
        quantity: item.quantity
      )
      item.product.decrement!(:stock, item.quantity)
    end
  end

  def clear_cart
    current_user.cart.cart_items.destroy_all
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
      Product.find(order_item.product_id).increment!(:stock,
                                                     order_item.quantity)
    end
  end

  def load_user
    @user = User.find(params[:user_id])
    return if @user

    render json: {error: I18n.t("users.not_found")}, status: :not_found
  end
end
