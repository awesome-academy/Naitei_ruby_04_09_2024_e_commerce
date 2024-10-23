class Ability
  include CanCan::Ability

  def initialize user
    if user.admin?
      admin_permissions
    else
      user_permissions(user)
    end
  end

  private

  def admin_permissions
    can :manage, :all
  end

  def user_permissions user
    cannot :manage, Admin::AdminController

    allow_read_permissions
    allow_order_permissions(user)
    allow_cart_permissions(user)
    allow_address_permissions(user)
    allow_review_permissions(user)
    allow_notification_permissions(user)
  end
end

private

def allow_read_permissions
  can :read, Product
  can :read, Category
end

def allow_order_permissions user
  can :create, Order
  can :read, Order, user_id: user.id
  can :update, Order, user_id: user.id
  can :manage, OrderItem, order: {user_id: user.id}
end

def allow_cart_permissions user
  can :manage, Cart, user_id: user.id
  can :manage, CartItem, cart: {user_id: user.id}
end

def allow_address_permissions user
  can :manage, Address, user_id: user.id
end

def allow_review_permissions user
  can :manage, Review, user_id: user.id
end

def allow_notification_permissions user
  can :manage, Notification, user_id: user.id
end
