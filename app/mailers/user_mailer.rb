class UserMailer < ApplicationMailer
  %i(password_reset order_confirm order_cancel
order_update).each do |email_type|
    define_method email_type do |user, *args|
      @user = user
      @order = args.first if args.any?
      mail to: user.email, subject: t(".#{email_type}")
    end
  end
end
