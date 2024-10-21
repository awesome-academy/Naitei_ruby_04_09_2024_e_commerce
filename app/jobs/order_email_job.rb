class OrderEmailJob < ApplicationJob
  queue_as :default

  def perform order, user, email_type
    case email_type
    when :cancel
      user.send_order_cancel_email(order)
    when :confirm
      user.send_order_confirm_email(order)
    when :update
      user.send_order_update_email(order)
    else
      raise ArgumentError, "Unknown email type: #{email_type}"
    end
  end
end
