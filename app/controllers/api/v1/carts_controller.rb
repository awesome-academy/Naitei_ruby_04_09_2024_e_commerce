class Api::V1::CartsController < Api::V1::ApplicationController
  before_action :authenticate_user!,
                :set_cart,
                only: %i(show
                        add_item
                        increment_item
                        decrement_item
                        remove_item)
  before_action :set_user, :correct_user,
                only: %i(show increment_item decrement_item remove_item)
  before_action :set_product_and_quantity, only: :add_item
  before_action :find_cart_item,
                only: %i(increment_item
                        decrement_item
                        remove_item)

  def show
    cart_items_query = @cart.cart_items.includes(product: :category)
    @cart_items = cart_items_query
    calculate_total
    render json: {id: @cart.id, cart_items: @cart_items, total: @total},
           status: :ok
  end

  def add_item
    @cart_item = @cart.cart_items.find_by(product_id: @product_id)
    if @cart_item.nil?
      add_new_item_to_cart
    else
      update_existing_cart_item
    end
    calculate_total
  end

  def increment_item
    if can_increment_item?
      increment_cart_item
    else
      render json: {
        message: I18n.t("api.carts.item_increment_fail"),
        total: @total,
        cart_item: @cart_item
      }, status: :ok
      return
    end
    calculate_total
    render json: {
      message: I18n.t("api.carts.item_increment_success"),
      total: @total,
      cart_item: @cart_item
    }, status: :ok
  end

  def decrement_item
    if can_decrement_item?
      decrement_cart_item
      calculate_total
      render json: {
        message: I18n.t("api.carts.item_decrement_success"),
        total: @total,
        cart_item: @cart_item
      }, status: :ok
    else
      remove_cart_item
      calculate_total
      render json: {
        message: I18n.t("carts.item_removed_success"),
        total: @total
      }, status: :ok
    end
  end

  def remove_item
    @cart_item.destroy
    calculate_total
    render json: {message: I18n.t("carts.item_removed_success"), total: @total},
           status: :ok
  end

  private

  def set_cart
    @cart = @current_user.cart || @current_user.create_cart
  end

  def set_user
    cart = Cart.find_by(id: params[:id])
    if cart.present?
      @user = cart.user
    else
      render json: {error: I18n.t("carts.cart_not_found")}, status: :not_found
    end
  end

  def set_product_and_quantity
    @quantity = params[:quantity].to_i
    @product_id = params[:product_id]
    @product = Product.find_by(id: @product_id)
    return if @product

    render json: {error: I18n.t("carts.product_not_found")}, status: :not_found
  end

  def find_cart_item
    @cart_item = @cart.cart_items.find_by(id: params[:cart_item_id])
    if @cart_item
      @product = @cart_item.product
    else
      render json: {error: I18n.t("carts.cart_item_not_found")},
             status: :not_found
    end
  end

  def add_new_item_to_cart
    if @quantity > @product.stock
      render json: {error: I18n.t("carts.insufficient_stock")},
             status: :unprocessable_entity
    else
      @cart_item = @cart.cart_items.build(product_id: @product.id,
                                          quantity: @quantity)
      if @cart_item.save
        render json: {message: I18n.t("api.carts.item_added")},
               status: :ok
      else
        render json: {error: I18n.t("carts.item_added_error")},
               status: :unprocessable_entity
      end
    end
  end

  def update_existing_cart_item
    new_quantity = @cart_item.quantity + @quantity
    if new_quantity > @product.stock + @cart_item.quantity
      render json: {error: I18n.t("carts.insufficient_stock")},
             status: :unprocessable_entity
    elsif @cart_item.update(quantity: new_quantity)
      render json: {message: I18n.t("api.carts.item_added")},
             status: :ok
    else
      render json: {error: I18n.t("carts.item_added_error")},
             status: :unprocessable_entity
    end
  end

  def can_increment_item?
    @product.stock >= 1
  end

  def increment_cart_item
    @cart_item.quantity += 1
    return if @cart_item.save

    render json: {error: I18n.t("carts.insufficient_stock")},
           status: :unprocessable_entity
  end

  def can_decrement_item?
    @cart_item.quantity > 1
  end

  def decrement_cart_item
    @cart_item.quantity -= 1
    return if @cart_item.save

    render json: {error: I18n.t("carts.insufficient_stock")},
           status: :unprocessable_entity
  end

  def remove_cart_item
    @cart_item.quantity = 0
    @cart_item.destroy
  end

  def calculate_total
    cart_items_with_price = @cart.cart_items.includes(:product)
    @total = cart_items_with_price.sum("cart_items.quantity * products.price")
  end
end
