source "https://rubygems.org"
git_source(:github){|repo| "https://github.com/#{repo}.git"}

ruby "3.2.2"

gem "bcrypt", "~> 3.1.7"
gem "bootsnap", require: false
gem "config"
gem "devise", "~> 4.1"
gem "dotenv-rails", groups: [:development, :test]
gem "faker"
gem "font-awesome-sass"
gem "foreman", "~> 0.87.2"
gem "image_processing", "~> 1.2"
gem "importmap-rails"
gem "jbuilder"
gem "kredis"
gem "mysql2", "~> 0.5"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "puma", "~> 5.0"
gem "rails", "~> 7.0.5"
gem "rails-i18n"
gem "sassc-rails"
gem "sidekiq"
gem "sprockets-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 2.7"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i(mingw mswin x64_mingw jruby)

group :development, :test do
  gem "debug", platforms: %i(mri mingw x64_mingw)
  gem "rspec-rails", "~> 4.0.1"
  gem "rubocop", "~> 1.26", require: false
  gem "rubocop-checkstyle_formatter", require: false
  gem "rubocop-rails", "~> 2.14.0", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
