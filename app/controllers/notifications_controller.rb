class NotificationsController < ApplicationController
  before_action :set_user, :logged_in_user
  load_and_authorize_resource :notification, through: :user

  def mark_as_read
    if @notification.update(read: true)
      redirect_to user_order_order_details_path(@notification.user,
                                                @notification.order)
    else
      flash[:danger] = t "notifications.update_failed"
      redirect_to root_path
    end
  end
end
