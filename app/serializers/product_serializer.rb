class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :desc, :price, :stock, :img_url, :rating

  belongs_to :category
  has_many :reviews

  def img_url
    return unless object.image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(object.image,
                                                        only_path: true)
  end

  def category
    {
      id: object.category.id,
      name: object.category.name
    }
  end

  def reviews
    object.reviews.map do |review|
      {
        id: review.id,
        rating: review.rating,
        comment: review.comment,
        user_name: review.user.user_name
      }
    end
  end
end
