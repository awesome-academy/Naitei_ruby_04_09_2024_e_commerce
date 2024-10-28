FactoryBot.define do
  factory :review do
    association :user
    association :product
    association :order
    rating { Faker::Number.between(from: Settings.value.rate_min, to: Settings.value.rate_max) }
    comment { Faker::Lorem.sentence(word_count: 10) }
  end
end
