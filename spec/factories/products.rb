FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }  
    desc { Faker::Lorem.sentence(word_count: 15) } 
    price { Faker::Commerce.price(range: 10..1000.0) }  
    stock { 2 } 
    rating { rand(1..5) } 
    association :category  

    
    after(:build) do |product|
      product.image.attach(io: File.open(Rails.root.join("spec/support/images/sample_image.jpg")), filename: "sample_image.jpg", content_type: "image/jpeg")
    end    
  end
end
