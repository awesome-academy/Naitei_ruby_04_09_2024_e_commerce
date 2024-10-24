FactoryBot.define do
  factory :user do
    sequence(:user_name) { |n| "example_user_#{n}" }
    sequence(:email) { |n| "example_user_#{n}@gmail.com" }
    password { "12345678" }
    password_confirmation { "12345678" }
    role { :customer } 
    activated { true }
    activated_at { Time.zone.now }
  end
  
  factory :admin_user, class: "User" do
    sequence(:user_name) { |n| "admin_user_#{n}" }
    sequence(:email) { |n| "admin_user_#{n}@example.com" }
    password { "adminpassword" }
    password_confirmation { "adminpassword" }
    role { :admin }
    activated { true }
    activated_at { Time.zone.now }
  end
end
