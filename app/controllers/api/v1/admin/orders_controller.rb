class Api::V1::Admin::OrdersController < Api::V1::ApplicationController
  before_action :find_order, only: %i(show update)

  def index
    @q = Order.ransack(params[:q])
    @orders = filtered_orders(@q.result.order(id: :desc))
    render json: @orders, each_serializer: OrderSerializer, status: :ok
  end

  def show
    render json: @order, serializer: OrderSerializer, status: :ok
  end

  def update
    ActiveRecord::Base.transaction do
      handle_cancel_order if cancel_reason_present?
      @order.update!(order_params)

      if params[:order][:address].present? && @order.address.present?
        @order.address.update!(address_params)
      end

      OrderEmailJob.perform_later(@order, @order.user, :update)
      render json: {message: I18n.t("admin.orders_admin.update.success")},
             status: :ok
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

    render json: {message: I18n.t("admin.orders_admin.batch_update.success")},
           status: :ok
  rescue ActiveRecord::RecordInvalid => e
    handle_batch_update_error(e)
  end

  private

  def update_orders order_ids, status
    orders = Order.by_ids(order_ids)

    orders.each do |order|
      if order.cancelled?
        add_cancelled_order_alert(order)
      else
        order.update!(status:)
        OrderEmailJob.perform_later(order, order.user, :update)
      end
    end
  end

  def add_cancelled_order_alert order
    flash[:alert] ||= ""
    flash[:alert] += "#{t('admin.orders_admin.batch_update.cancelled_order',
                          order_id: order.id)} "
  end

  def handle_batch_update_error exception
    render json: {
      error: t("admin.orders_admin.batch_update.error",
               errors: exception.record.errors.full_messages.join(", "))
    }, status: :unprocessable_entity
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

    render json: {error: I18n.t("admin.orders_admin.not_found")},
           status: :not_found
  end

  def order_params
    params.require(:order).permit(Order::UPDATE_ORDER_ADMIN)
  end

  def address_params
    params.require(:order).require(:address)
          .permit(Address::ADDRESS_REQUIRE_ATTRIBUTES)
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
    render json: {
      error: if exception.record == @order
               t("admin.orders_admin.update.error_with_order",
                 errors: order_errors_message)
             else
               t("admin.orders_admin.update.error_with_address")
             end
    }, status: :unprocessable_entity
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
