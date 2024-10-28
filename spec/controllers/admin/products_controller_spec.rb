require "rails_helper"

RSpec.describe Admin::ProductsController, type: :controller do
  let!(:admin_user) { create(:admin_user) }
  let!(:product) { create(:product) }
  let!(:category) { create(:category) }

  before do
    sign_in admin_user
  end

  describe "GET #index" do
    it "assigns @products and @categories" do
      get :index
      expect(assigns(:products)).to include(product)
      expect(assigns(:categories)).to include([category.name, category.id])
    end

    it "paginates products" do
      get :index
      expect(controller.instance_variable_get(:@pagy)).to be_present
    end
  end

  describe "GET #show" do
    it "assigns the requested product to @product" do
      get :show, params: { id: product.id }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe "GET #new" do
    it "assigns a new product to @product and @categories" do
      get :new
      expect(assigns(:product)).to be_a_new(Product)
      expect(assigns(:categories)).to be_present
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      it "creates a new product and redirects" do
        expect {
        post :create, params: { product: attributes_for(:product, category_id: category.id) }
      }.to change(Product, :count).by(1)
        expect(flash[:success]).to eq("Sản phẩm đã được tạo thành công.")
        expect(response).to redirect_to(admin_product_path(Product.last))
      end
    end

    context "with invalid attributes" do
      it "does not create a product and renders new template" do
        expect {
          post :create, params: { product: attributes_for(:product, name: nil) }
        }.not_to change(Product, :count)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #edit" do
    it "assigns the requested product to @product" do
      get :edit, params: { id: product.id }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe "PATCH #update" do
    context "with valid parameters" do
      let(:new_attributes) { { name: "Updated Product" } }

      it "updates the requested product" do
        patch :update, params: { id: product.id, product: new_attributes }
        product.reload
        expect(product.name).to eq("Updated Product")
        expect(flash[:success]).to eq("Sản phẩm đã được cập nhật thành công.")
        expect(response).to redirect_to(admin_product_path(product))
      end
    end

    context "with invalid parameters" do
      it "does not update the product and re-renders the edit template" do
        patch :update, params: { id: product.id, product: { name: nil } }
        expect(product.reload.name).not_to eq(nil)
        expect(flash[:alert]).to eq("Cập nhật sản phẩm thất bại.")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested product" do
      expect {
        delete :destroy, params: { id: product.id }
      }.to change(Product, :count).by(-1)

      expect(flash[:success]).to eq("Sản phẩm đã được xóa thành công.")
      expect(response).to redirect_to(admin_products_path)
    end

    it "handles destroy errors" do
      allow_any_instance_of(Product).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      delete :destroy, params: { id: product.id }
      expect(flash[:alert]).to eq("Xóa sản phẩm thất bại.")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
