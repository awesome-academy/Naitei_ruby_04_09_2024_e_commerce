class Admin::UsersController < Admin::AdminController
  before_action :find_user, only: %i(show edit update destroy toggle_activation)

  def index
    @pagy, @users = pagy User.filtered_and_sorted(params)
  end

  def show; end

  def edit
    return unless @user.admin?

    flash[:alert] = t("admin.users_admin.update.admin_cannot_update")
    redirect_to admin_users_path
  end

  def update
    if @user.admin?
      handle_admin_update
    else
      handle_user_update
    end
  end

  def destroy
    if @user.activated?
      handle_active_user_destroy
    else
      handle_user_destroy
    end
  end

  def toggle_activation
    if @user.admin?
      flash[:alert] = t("admin.users_admin.toggle_activation.admin_not_allowed")
    else
      handle_toggle_activation
    end
    redirect_to admin_users_path
  end

  private

  def find_user
    @user = User.find_by(id: params[:id])
    return if @user

    flash[:alert] = t("admin.users_admin.not_found")
    redirect_to admin_users_path
  end

  def handle_admin_update
    flash[:alert] = t("admin.users_admin.update.admin_cannot_update")
    redirect_to admin_users_path
  end

  def handle_user_update
    User.transaction do
      if @user.update(user_params)
        flash[:success] = t("admin.users_admin.update.success")
        redirect_to admin_user_path(@user)
      else
        flash.now[:alert] = t("admin.users_admin.update.failure")
        render :edit, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  def handle_active_user_destroy
    flash[:alert] = t("admin.users_admin.destroy.cannot_delete_active")
    redirect_to admin_user_path(@user)
  end

  def handle_user_destroy
    User.transaction do
      @user.destroy
      flash[:success] = t("admin.users_admin.destroy.success")
      redirect_to admin_users_path
    end
  end

  def handle_toggle_activation
    User.transaction do
      @user.update(activated: !@user.activated?)
      flash[:success] = if @user.activated?
                          t("admin.users_admin.activate.success")
                        else
                          t("admin.users_admin.inactivate.success")
                        end
    end
  end

  def user_params
    params.require(:user).permit(User::USER_ADMIN_ATTRIBUTES)
  end
end
