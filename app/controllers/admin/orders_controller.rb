class Admin::OrdersController < Admin::AdminController
  include Pagy::Backend
  before_action :find_order, only: %i(show edit update)

  def index
    @q = Order.ransack(params[:q])
    @pagy, @orders = pagy(
      filtered_orders(@q.result)
        .ordered_by_updated_at
    )
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
      OrderEmailJob.perform_later(@order, @order.user, :update)
      redirect_to admin_order_path(@order)
    rescue ActiveRecord::RecordInvalid => e
      handle_update_error(e)
    end
  end

  def batch_update
    order_ids = order_ids_param
    status = status_param

    ActiveRecord::Base.transaction do
      update_orders(order_ids, status)
    end

    flash[:success] = t("admin.orders_admin.batch_update.success")
    redirect_to admin_orders_path
  rescue ActiveRecord::RecordInvalid => e
    handle_batch_update_error(e)
  end

  private

  def update_orders order_ids, status
    orders = Order.where(id: order_ids)

    orders.each do |order|
      if order.cancelled?
        flash[:alert] =
          if flash[:alert].present?
            "#{flash[:alert]} #{t(
              'admin.orders_admin.batch_update.cancelled_order',
              order_id: order.id
            )}"
          else
            t(
              "admin.orders_admin.batch_update.cancelled_order",
              order_id: order.id
            )
          end
      else
        order.update!(status:)
        OrderEmailJob.perform_later(order, order.user, :update)
      end
    end
  end

  def handle_batch_update_error exception
    flash[:alert] =
      t("admin.orders_admin.batch_update.error",
        errors: exception.record.errors.full_messages.join(", "))
    redirect_to admin_orders_path
  end

  def order_ids_param
    params[:order_ids] || []
  end

  def status_param
    params[:status]
  end

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

  def filtered_orders orders
    if params[:status].present?
      orders.by_status(params[:status])
    else
      orders
    end
  end
end
