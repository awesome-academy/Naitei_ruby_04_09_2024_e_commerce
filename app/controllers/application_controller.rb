class ApplicationController < ActionController::Base
  include Pagy::Backend
  include SessionsHelper

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:user_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:user_name])
  end

  private
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def logged_in_user
    return if logged_in?

    flash[:danger] = t ".unauthenticated"
    store_location
    redirect_to new_user_session_path, status: :see_other
  end

  def correct_user
    return if current_user? @user

    flash[:danger] = t ".unauthorized"
    redirect_to root_path, status: :see_other
  end

  def after_sign_in_path_for resource
    if resource.admin?
      admin_dashboard_path
    else
      session[:forwarding_url] || root_path
    end
  end
end
