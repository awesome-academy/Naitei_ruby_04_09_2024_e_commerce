require "rails_helper"

RSpec.describe Review, type: :model do
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:order) { create(:order, user: user, status: :delivered) }
  let(:review) { build(:review, user: user, product: product, order: order) }

  describe "associations" do
    it { should belong_to(:product) }
    it { should belong_to(:user) }
    it { should belong_to(:order) }
  end

  describe "validations" do
    describe "rating" do
      it { should validate_presence_of(:rating) }
      it { should validate_numericality_of(:rating).is_greater_than_or_equal_to(Settings.value.rate_min) }
      it { should validate_numericality_of(:rating).is_less_than_or_equal_to(Settings.value.rate_max) }
    end

    describe "comment" do
      it { should validate_length_of(:comment).is_at_most(Settings.value.comment_length) }
    end
  end
  describe "scopes" do
    let(:review1) { create(:review, user: user, product: product, order: order, rating: 5) }
    let(:review2) { create(:review, user: user, product: create(:product), order: order, rating: 3) }
  
    before do
      review1
      review2
    end
  
    describe ".by_user_username" do
      it "returns reviews by the given user username" do
        reviews = Review.by_user_username(user.user_name)
        expect(reviews.count).to eq(2)
      end
    end
  
    describe ".by_product_name" do
      it "returns reviews for products matching the given name" do
        reviews = Review.by_product_name(product.name)
        expect(reviews.count).to eq(1)
      end
    end
  
    describe ".sort_by_rating" do
      it "returns reviews sorted by rating in descending order" do
        sorted_reviews = Review.sort_by_rating("desc")
        expect(sorted_reviews.first.rating).to eq(5)
      end
    end
  
    describe ".sort_by_created_at" do
      it "returns reviews sorted by created_at" do
        sorted_reviews = Review.sort_by_created_at("desc")
        expect(sorted_reviews.first.created_at).to be >= sorted_reviews.second.created_at
      end
    end
  
    describe ".by_rating" do
      it "returns reviews with the specified rating" do
        reviews = Review.by_rating(5)
        expect(reviews.count).to eq(1)
      end
    end
  end
  
end
