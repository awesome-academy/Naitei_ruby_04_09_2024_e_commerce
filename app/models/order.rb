class Order < ApplicationRecord
  UPDATE_ORDER = %i(address_id total status cancel_reason
payment_method).freeze
  UPDATE_ORDER_ADMIN = %i(status cancel_reason payment_method).freeze
  belongs_to :user
  belongs_to :address
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  enum status: {
    pending: 0,
    confirmed: 1,
    preparing: 2,
    delivering: 3,
    delivered: 4,
    cancelled: 5
  }

  validates :total, presence: true,
    numericality: {greater_than_or_equal_to: Settings.value.min_numeric}
  validates :status, presence: true
  validates :cancel_reason, presence: true, if: ->{cancelled?}

  after_update :send_order_notification
  after_create :send_order_notification

  scope :ordered_by_updated_at, ->{order(updated_at: :desc)}

  scope :by_username, lambda {|user_name|
    joins(:user).where(users: {user_name:}) if user_name.present?
  }

  scope :by_status, ->(status){where(status:) if status.present?}

  scope :sorted, lambda {|sort_column, sort_direction|
    valid_columns = %w(created_at total)
    if valid_columns.include?(sort_column)
      order("#{sort_column} #{sort_direction}")
    else
      order("created_at desc")
    end
  }
  scope :total_revenue, ->{where(status: "delivered").sum(:total)}

  scope :with_status, lambda {|status|
                        where(status:) if statuses.key?(status)
                      }

  def send_order_notification
    Notification.create!(
      user:,
      order: self,
      message: "order.updated",
      read: false,
      status:
    )
  end

  scope :created_at_month, lambda {|month|
    where(
      created_at: month.beginning_of_month..
                  month.end_of_month
    )
  }
  def self.cal_sum_orders orders
    orders.sum(:total)
  end
end
