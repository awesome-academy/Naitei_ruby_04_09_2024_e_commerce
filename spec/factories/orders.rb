FactoryBot.define do
  factory :order do
    association :user
    association :address
    total { Faker::Commerce.price(range: 10..100.0) }
    payment_method { "cash_on_delivery" } 
    status { Order.statuses.keys.sample }
    cancel_reason { nil } 

    trait :cancelled do
      status { :cancelled }
      cancel_reason { Faker::Lorem.sentence }
    end
  end
end
