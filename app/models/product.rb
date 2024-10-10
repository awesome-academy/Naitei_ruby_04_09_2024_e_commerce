class Product < ApplicationRecord
  PRODUCT_ADMIN_ATTRIBUTES = [:name, :desc, :price, :stock,
:category_id, :img_url].freeze
  belongs_to :category
  has_many :cart_item, dependent: :destroy
  has_many :order_item, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :orders, through: :order_items

  validates :name, presence: true
  validates :price, presence: true,
    numericality: {greater_than_or_equal_to: Settings.value.min_numeric}
  validates :stock, presence: true,
    numericality: {greater_than_or_equal_to: Settings.value.min_numeric}
  validates :rating,
            numericality: {greater_than_or_equal_to: Settings.value.min_numeric,
                           less_than_or_equal_to: Settings.value.rate_max},
            allow_nil: true

  scope :search_by_name, ->(query){where("name LIKE ?", "%#{query}%")}
  scope :by_category, lambda {|category_id|
                        where(category_id:) if category_id.present?
                      }
  scope :filtered, ->(params){by_category(params[:category]).distinct}
  scope :sorted, lambda {|sort_by, direction|
    column = if %w(name price stock created_at).include?(sort_by)
               sort_by
             else
               "created_at"
             end
    order(column => direction)
  }

  def review_by_user user
    reviews.includes(:user).find_by(user_id: user.id)
  end

  def average_rating
    reviews.average(:rating).to_f.round(1)
  end

  def update_average_rating
    update(rating: average_rating)
  end
end
