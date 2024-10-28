require "rails_helper"

RSpec.describe ProductsController, type: :controller do
  let(:product) { create(:product) }
  let(:user) { create(:user) }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @products" do
      get :index
      expect(assigns(:products)).to eq([product])
    end

    it "assigns @product_count" do
      get :index
      expect(assigns(:product_count)).to eq(Product.count)
    end
  end

  describe "GET #show" do
    context "when the product exists" do
      it "returns a successful response" do
        get :show, params: { id: product.id }
        expect(response).to be_successful
      end

      it "assigns @product" do
        get :show, params: { id: product.id }
        expect(assigns(:product)).to eq(product)
      end

      it "assigns @reviews" do
        review = create(:review, product: product, user: user, rating: 4, comment: "Great product!")
        get :show, params: { id: product.id }
        expect(assigns(:reviews)).to include(review)
      end

      it "assigns @reviews_count" do
        create(:review, product: product, user: user, rating: 4, comment: "Great product!")
        get :show, params: { id: product.id }
        expect(assigns(:reviews_count)).to eq(1)
      end
    end

    context "when the product does not exist" do
      it "redirects to the root path" do
        get :show, params: { id: -1 }
        expect(response).to redirect_to(root_path)
      end

      it "sets a flash message" do
        get :show, params: { id: -1 }
        expect(flash[:danger]).to eq("Sản phẩm không tìm thấy.")
      end
    end
  end
end
