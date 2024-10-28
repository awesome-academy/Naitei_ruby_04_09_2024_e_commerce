class Api::V1::ApplicationController < ActionController::API
  require "./lib/authentication"

  private

  def authenticate_user!
    token = request.headers["Authorization"]
    user_id = Authentication.decode(token)["user_id"] if token

    @current_user = User.find_by(id: user_id)

    return if @current_user

    render json: {error: I18n.t("errors.login_required")},
           status: :unauthorized
  end

  def authenticate_admin!
    return if @current_user&.admin?

    render json: {error: I18n.t("errors.forbidden_access")},
           status: :forbidden
  end
end
