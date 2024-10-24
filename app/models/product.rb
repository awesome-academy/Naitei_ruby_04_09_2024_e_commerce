class Product < ApplicationRecord
  PRODUCT_ADMIN_ATTRIBUTES = [:name, :desc, :price, :stock,
:category_id, :image].freeze
  belongs_to :category
  has_many :cart_item, dependent: :destroy
  has_many :order_item, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :orders, through: :order_items
  has_one_attached :image

  validates :name, presence: true
  validates :price, presence: true,
    numericality: {greater_than_or_equal_to: Settings.value.min_numeric}
  validates :stock, presence: true,
    numericality: {greater_than_or_equal_to: Settings.value.min_numeric}
  validates :rating,
            numericality: {greater_than_or_equal_to: Settings.value.min_numeric,
                           less_than_or_equal_to: Settings.value.rate_max},
            allow_nil: true

  scope :sorted, lambda {|sort_by, direction|
    column = if %w(name price stock created_at).include?(sort_by)
               sort_by
             else
               "created_at"
             end
    order(column => direction)
  }

  scope :highest_rated, ->{order(rating: :desc).first}

  ransack_alias :product_name, :name
  ransack_alias :category_name, "categories.name"
  ransack_alias :price, :price
  ransack_alias :stock, :stock

  scope :search_all, lambda {|query|
    if query.present?
      query_value = query.to_f
      joins(:category).where(
        "products.name LIKE :query OR categories.name LIKE :query",
        query: "%#{query}%"
      ).or(
        where(products: {price: query_value}).or(
          where(products: {stock: query_value})
        )
      )
    end
  }
  class << self
    def ransackable_scopes _auth_object = nil
      %i(search_all)
    end

    def ransackable_attributes _auth_object = nil
      %w(name price stock category_id product_name category_name)
    end

    def ransackable_associations _auth_object = nil
      %w(category)
    end
  end
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
