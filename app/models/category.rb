class Category < ApplicationRecord
  CATEGORY_ADMIN_ATTRIBUTES = [:name].freeze

  has_many :products, dependent: :nullify

  scope :search_by_name, ->(query){where("name LIKE ?", "%#{query}%")}

  validates :name,
            presence: true,
            uniqueness: true,
            length: {maximum: Settings.value.max_category_name}

  scope :by_name, lambda {|name|
                    where("name LIKE ?", "%#{name}%") if name.present?
                  }

  scope :sorted, lambda {|sort_by, direction|
    column = %w(name created_at).include?(sort_by) ? sort_by : "created_at"
    direction = %w(asc desc).include?(direction) ? direction : "asc"
    order(column => direction)
  }

  scope :sort_by_params, lambda {|params|
    by_name(params[:name])
      .sorted(params[:sort], params[:direction])
  }
end
