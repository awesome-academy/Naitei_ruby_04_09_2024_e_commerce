set :path, "/Users/nguyentritin/Documents/ruby/project/project/Naitei_ruby_04_09_2024_e_commerce"

job_type :rbenv_rake, "cd :path && /Users/nguyentritin/.rbenv/versions/3.2.2/bin/bundle exec rake :task RAILS_ENV=:environment :output"

every "0 8 1 * *" do
  rbenv_rake "admin_mailer:monthly_summary_email"
end
