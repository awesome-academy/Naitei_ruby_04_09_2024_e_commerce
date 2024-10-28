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

  scope :search, lambda {|query|
    if query.present?
      joins(:user, :address)
        .where("users.user_name LIKE :query OR addresses.receiver_name
        LIKE :query", query: "%#{query}%")
    end
  }
  scope :by_status, ->(status){where(status:) || all}

  scope :total_revenue, ->{where(status: "delivered").sum(:total)}

  scope :with_status, lambda {|status|
                        where(status:) if statuses.key?(status)
                      }
  scope :created_at_month, lambda {|month|
                             where(
                               created_at: month.beginning_of_month..
                                           month.end_of_month
                             )
                           }
  class << self
    def ransackable_attributes _auth_object = nil
      %w(created_at id status total)
    end

    def cal_sum_orders orders
      orders.sum(:total)
    end

    def ransackable_scopes _auth_object = nil
      [:search]
    end
  end
  def send_order_notification
    Notification.create!(
      user:,
      order: self,
      message: "order.updated",
      read: false,
      status:
    )
  end
end
