require "rails_helper"

RSpec.describe Product, type: :model do
  let!(:category) { create(:category) }
  let!(:product) { build(:product, category: category) }
  let!(:product1) { create(:product, name: "A Product", price: 10, stock: 5, category: category) }
  let!(:product2) { create(:product, name: "B Product", price: 20, stock: 10, category: category) }
  let!(:product3) { create(:product, name: "C Product", price: 30, stock: 15, category: category) }



  describe "validations" do
    context "when valid attributes are provided" do
      it "is valid with valid attributes" do
        expect(product).to be_valid
      end
    end

    context "when invalid attributes are provided" do
      it "is not valid without a name" do
        product.name = nil
        expect(product).not_to be_valid
      end

      it "is not valid without a price" do
        product.price = nil
        expect(product).not_to be_valid
      end

      it "is not valid with a price less than the minimum" do
        product.price = Settings.value.min_numeric - 1
        expect(product).not_to be_valid
      end

      it "is not valid without a stock" do
        product.stock = nil
        expect(product).not_to be_valid
      end

      it "is not valid with a stock less than the minimum" do
        product.stock = Settings.value.min_numeric - 1
        expect(product).not_to be_valid
      end

      it "is valid with a rating within the valid range" do
        product.rating = Settings.value.rate_max - 1
        expect(product).to be_valid
      end

      it "is not valid with a rating above the maximum" do
        product.rating = Settings.value.rate_max + 1
        expect(product).not_to be_valid
      end

      it "is not valid with a rating below the minimum" do
        product.rating = Settings.value.min_numeric - 1
        expect(product).not_to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".sorted" do
      context "when sorting by name" do
        it "sorts products by name in ascending order" do
          expect(Product.sorted("name", "asc")).to eq([product1, product2, product3])
        end
      end

      context "when sorting by price" do
        it "sorts products by price in descending order" do
          expect(Product.sorted("price", "desc")).to eq([product3, product2, product1])
        end

        it "sorts products by created_at in ascending order by default" do
          expect(Product.sorted("invalid_column", "asc")).to eq([product1, product2, product3])
        end
      end
    end

    describe ".highest_rated" do
      before do
        product1.update(rating: 4)
        product2.update(rating: 5)
        product3.update(rating: 3)
      end
      it "returns the highest rated product" do
        expect(Product.highest_rated).to eq(product2)
      end
    end

    describe ".search_all" do
      it "returns products matching the name query" do
        expect(Product.search_all("A")).to include(product1)
      end

      it "returns products matching the price query" do
        expect(Product.search_all("10")).to include(product1)
      end

      it "returns products matching the stock query" do
        expect(Product.search_all("5")).to include(product1)
      end

      it "returns products matching the category name" do
        expect(Product.search_all(category.name)).to include(product1)
      end
    end
  end

  describe "instance methods" do
    let(:user) { create(:user) }

    before do
      product.save
    end

    describe "#average_rating" do
      context "when there are reviews" do
        before do
          create(:review, product: product, rating: 4)
          create(:review, product: product, rating: 5)
        end
        it "calculates the average rating of the product" do
          expect(product.average_rating).to eq(4.5)
        end
      end

      context "when there are no reviews" do
        it "returns 0.0" do
          expect(product.average_rating).to eq(0.0)
        end
      end
    end

    describe "#review_by_user" do
      context "when the user has a review" do
        before do
          create(:review, product: product, user: user, rating: 4, comment: "Great product!")
        end
        it "returns the review made by the user" do
          expect(product.review_by_user(user)).to be_present
        end
      end

      context "when the user has not reviewed the product" do
        let(:another_user) { create(:user) }

        it "returns nil" do
          expect(product.review_by_user(another_user)).to be_nil
        end
      end
    end

    describe "#update_average_rating" do
      context "when there are reviews" do
        before do
          create(:review, product: product, user: user, rating: 5, comment: "Excellent!")
          create(:review, product: product, user: user, rating: 4, comment: "Great!")
        end
        it "updates the product rating with the average rating" do
          product.update_average_rating

          expect(product.average_rating).to eq(4.5)
        end
      end

      context "when there are no reviews" do
        it "does not change the average rating" do
          original_average = product.average_rating
          product.update_average_rating

          expect(product.average_rating).to eq(original_average)
        end
      end
    end
  end
end
