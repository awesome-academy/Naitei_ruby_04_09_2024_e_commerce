namespace :admin_mailer do
  desc "Send monthly summary email"
  task monthly_summary_email: :environment do
    AdminMailer.monthly_summary_email.deliver_now
  end
end
