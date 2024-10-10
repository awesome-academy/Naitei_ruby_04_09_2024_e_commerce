class Admin::OrdersController < Admin::AdminController
  include Pagy::Backend
  before_action :find_order, only: %i(show edit update)

  def index
    @pagy, @orders = pagy(filtered_orders.sorted(params[:sort],
                                                 params[:direction]))
  end

  def show
    @product = @order.products
  end

  def edit; end

  def update
    ActiveRecord::Base.transaction do
      handle_cancel_order if cancel_reason_present?
      @order.update!(order_params)
      @order.address.update!(address_params)
      flash[:success] = t("admin.orders_admin.update.success")
      @order.user.send_order_update_email @order
      redirect_to admin_order_path(@order)
    rescue ActiveRecord::RecordInvalid => e
      handle_update_error(e)
    end
  end

  private

  def find_order
    @order = Order.find_by(id: params[:id])
    return if @order

    flash[:alert] = t ".not_found"
    redirect_to root_path
  end

  def order_params
    params.require(:order).permit Order::UPDATE_ORDER_ADMIN
  end

  def address_params
    params.require(:order).require(:address).permit(
      Address::ADDRESS_REQUIRE_ATTRIBUTES
    )
  end

  def cancel_reason_present?
    params[:order][:cancel_reason].present?
  end

  def handle_cancel_order
    @order.cancel_reason = params[:order][:cancel_reason]
    @order.cancelled!
    restore_product_stock
  end

  def restore_product_stock
    @order.order_items.each do |order_item|
      order_item.product.increment!(:stock, order_item.quantity)
    end
  end

  def handle_update_error exception
    flash[:alert] = if exception.record == @order
                      t("admin.orders_admin.update.error_with_order",
                        errors: order_errors_message)
                    else
                      t("admin.orders_admin.update.error_with_address")
                    end
    redirect_to edit_admin_order_path(@order), status: :unprocessable_entity
  end

  def order_errors_message
    @order.errors.full_messages.join(", ")
  end

  def filtered_orders
    Order.by_status(params[:status])
  end
end
