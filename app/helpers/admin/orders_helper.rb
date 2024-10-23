module Admin
  module OrdersHelper
    def order_status_label status
      case status.to_sym
      when :pending
        t("orders.status.pending")
      when :confirmed
        t("orders.status.confirmed")
      when :preparing
        t("orders.status.preparing")
      when :delivering
        t("orders.status.delivering")
      when :delivered
        t("orders.status.delivered")
      when :cancelled
        t("orders.status.cancelled")
      else
        t("orders.status.unknown")
      end
    end

    def payment_method_label payment_method
      case payment_method.to_sym
      when :cash_on_delivery
        t("orders.payment_method.cash_on_delivery")
      when :credit_card
        t("orders.payment_method.credit_card")
      else
        t("orders.payment_method.unknown")
      end
    end

    def order_status_class status
      case status.to_sym
      when :pending
        "bg-yellow-100 text-yellow-700"
      when :confirmed
        "bg-blue-100 text-blue-700"
      when :preparing
        "bg-orange-100 text-orange-700"
      when :delivering
        "bg-teal-100 text-teal-700"
      when :delivered
        "bg-green-100 text-green-700"
      when :cancelled
        "bg-red-100 text-red-700"
      else
        "bg-gray-100 text-gray-700"
      end
    end

    def status_update_select_tag selected_status
      statuses = Order.statuses.keys.reject{|status| status == "cancelled"}
      status_options = statuses.map do |status|
        [t("orders.status.#{status}"), status]
      end

      label_tag(:status_update, t("admin.orders_admin.index.update_status"),
                class: "mr-2") +
        select_tag(:status, options_for_select(status_options, selected_status),
                   class: "form-select")
    end
  end
end
