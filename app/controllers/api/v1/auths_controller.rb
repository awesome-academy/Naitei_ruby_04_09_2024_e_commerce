class Api::V1::AuthsController < Api::V1::ApplicationController
  def login
    user = User.find_for_database_authentication(email: params[:email])

    if user&.valid_password?(params[:password])
      render json: {jwt_token: Authentication.encode({user_id: user.id})},
             status: :ok
    else
      render json: {error: I18n.t("errors.invalid_credentials")},
             status: :unauthorized
    end
  end
end
