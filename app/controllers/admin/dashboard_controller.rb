class Admin::DashboardController < Admin::AdminController
  def index
    @total_categories = Category.count
    @total_products = Product.count
    @total_users = User.count
    @total_orders = Order.count
    @total_revenue = Order.total_revenue
    @highest_rated_product = Product.highest_rated
    @top_user = User.top_user
    @top_user_order_count = @top_user.present? ? @top_user.orders.count : 0
    @monthly_revenue = calculate_monthly_revenue
    @order_status_counts = calculate_order_status_counts
    @product_stock_counts = calculate_product_stock_counts
    @rating_counts = calculate_rating_counts
  end

  def profile; end

  private

  def calculate_monthly_revenue
    monthly_revenue = Date::MONTHNAMES[1..12].index_with{|_month| 0}

    Order.delivered
         .group("EXTRACT(MONTH FROM updated_at)")
         .sum(:total)
         .each do |month, total|
           monthly_revenue[Date::MONTHNAMES[month]] = total
         end

    monthly_revenue
  end

  def calculate_order_status_counts
    valid_statuses = Order.statuses.keys

    status_counts = Order.group(:status).count

    valid_statuses.index_with do |status|
      {
        name: I18n.t("dashboard.#{status}"),
        count: status_counts[status] || 0
      }
    end
  end

  def calculate_product_stock_counts
    Product.all.index_with(&:stock)
  end

  def calculate_rating_counts
    (1..5).index_with do |star|
      Review.where(rating: star).count
    end
  end
end
