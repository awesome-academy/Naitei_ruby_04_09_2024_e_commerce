class OrderSerializer < ActiveModel::Serializer
  attributes :id, :status, :total, :cancel_reason, :created_at, :updated_at

  has_one :user
  has_many :order_items

  def user
    {
      id: object.user.id,
      name: object.user.user_name,
      email: object.user.email
    }
  end

  def order_items
    object.order_items.map do |order_item|
      {
        product_id: order_item.product.id,
        product_name: order_item.product.name,
        quantity: order_item.quantity,
        price: order_item.price
      }
    end
  end
end
