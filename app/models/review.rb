class Review < ApplicationRecord
  REVIEW_REQUIRE_ATTRIBUTES = %i(rating comment).freeze
  belongs_to :product
  belongs_to :user

  validates :rating, presence: true,
            numericality: {greater_than_or_equal_to: Settings.value.rate_min,
                           less_than_or_equal_to: Settings.value.rate_max}
  validates :comment, length: {maximum: Settings.value.comment_length}
end
