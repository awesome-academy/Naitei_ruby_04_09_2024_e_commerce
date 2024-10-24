class AdminMailer < ApplicationMailer
  include ActionView::Helpers::NumberHelper
  def format_currency amount
    number_to_currency(amount, unit: "₫", format: "%n %u", precision: 0,
                       delimiter: ".", separator: ",")
  end

  def monthly_summary_email
    admin_user = User.find_by role: "admin"
    last_month = Time.current.last_month
    orders = Order.created_at_month last_month
    @sum = format_currency Order.cal_sum_orders(orders)
    mail to: admin_user.email, subject: t(".title")
  end
end
