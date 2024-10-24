class Category < ApplicationRecord
  CATEGORY_ADMIN_ATTRIBUTES = [:name].freeze

  has_many :products, dependent: :nullify

  validates :name,
            presence: true,
            uniqueness: true,
            length: {maximum: Settings.value.max_category_name}

  scope :by_name, lambda {|name|
    where("categories.name LIKE ?", "%#{name}%") if name.present?
  }

  scope :search, lambda {|query|
    results = by_name(query)
    if query.present? && query.match?(/^\d{2}-\d{2}-\d{4}$/)
      date = begin
        Date.strptime(query, "%d-%m-%Y")
      rescue StandardError
        nil
      end
      if date
        results = results.or(where("DATE(categories.created_at) = ?", date))
      end
    end
    results
  }

  def self.with_product_count
    left_joins(:products)
      .select("categories.*, COUNT(products.id) AS products_count")
      .group("categories.id")
  end

  class << self
    def ransackable_scopes auth_object = nil
      if auth_object&.role == "admin"
        [:by_name, :search]
      else
        [:by_name]
      end
    end

    def ransackable_attributes _auth_object = nil
      %w(created_at name)
    end
  end

  def products_count
    products.size
  end
end
