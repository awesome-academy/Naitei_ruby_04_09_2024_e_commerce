class User < ApplicationRecord
  SIGN_UP_REQUIRE_ATTRIBUTES = %i(user_name email password
password_confirmation avatar).freeze
  RESET_PARAMS = %i(password password_confirmation).freeze
  USER_ADMIN_ATTRIBUTES = %i(user_name email role activated).freeze

  has_one_attached :avatar do |attachable|
    attachable.variant :display, resize_to_limit: [Settings.ui.avatar_size,
                            Settings.ui.avatar_size]
  end
  has_many :orders, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :notifications, dependent: :destroy

  enum role: {customer: 0, admin: 1}

  before_save :downcase_email

  validates :user_name, presence: true,
            length: {maximum: Settings.value.max_user_name}

  validates :email,
            presence: true,
            length: {maximum: Settings.value.max_user_email},
            format: {with: Settings.value.valid_email},
            uniqueness: {case_sensitive: false}

  validates :password,
            presence: true,
            length: {minimum: Settings.value.min_user_password},
            allow_nil: true

  scope :search_by_user_name, lambda {|query|
                                if query.present?
                                  where("user_name LIKE ?", "%#{query}%")
                                end
                              }
  scope :by_activation_status, lambda {|status|
                                 where(activated: status) if status.present?
                               }
  scope :sorted, lambda {|column, direction|
    order("#{column} #{direction}") if column.present?
  }
  scope :by_role, lambda {|role|
                    where(role:) if role.present?
                  }
  scope :filtered_and_sorted, lambda {|params|
    search_by_user_name(params[:user_name])
      .by_activation_status(params[:activated])
      .by_role(params[:role])
      .sorted(params[:sort], params[:direction])
  }
  def self.top_user
    joins(:orders)
      .group("users.id")
      .order("COUNT(orders.id) DESC")
      .first
  end

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  %i(password_reset order_confirm order_cancel
order_update).each do |email_type|
    define_method "send_#{email_type}_email" do |*args|
      UserMailer.send(email_type, self, *args).deliver_now
    end
  end

  private
  def downcase_email
    email.downcase!
  end
end
