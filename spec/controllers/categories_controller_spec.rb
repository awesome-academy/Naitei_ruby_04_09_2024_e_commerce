require "rails_helper"

RSpec.describe CategoriesController, type: :controller do
  let!(:category) { create(:category) }

  describe "GET #index" do
    before do
      get :index
    end
    it "assigns categories to @categories" do
      expect(assigns(:categories)).to match_array(Category.includes(:products))
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    it "paginates categories" do
      expect(assigns(:pagy)).to be_present
    end
  end

  describe "GET #show" do
    context "when the category is found" do
      before do
        get :show, params: { id: category.id }
      end
      it "assigns the requested category to @category" do
        expect(assigns(:category)).to eq(category)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end

      it "loads products for the category" do
        expect(assigns(:products)).to eq(category.products)
      end

      it "paginates products" do
        expect(assigns(:pagy)).to be_present
      end

      it "counts the number of products in the category" do
        expect(assigns(:product_count)).to eq(category.products.count)
      end
    end

    context "when the category is not found" do
      before { get :show, params: { id: "invalid_id" } }
    
      it "redirects to categories_path" do
        expect(response).to redirect_to(categories_path)
      end
    
      it "sets a flash alert" do
        expect(flash[:alert]).to eq(I18n.t("categories.not_found"))
      end
    end
  end
end
