class Category < ApplicationRecord
  has_many :products, dependent: :nullify

  validates :name,
            presence: true,
            uniqueness: true,
            length: {maximum: Settings.value.max_category_name}

  scope :search_by_name, ->(query){where("name LIKE ?", "%#{query}%")}
end
