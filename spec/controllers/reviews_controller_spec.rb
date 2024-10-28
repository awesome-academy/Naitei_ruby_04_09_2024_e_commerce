require "rails_helper"

RSpec.describe ReviewsController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, status: :delivered) }
  let(:product) { create(:product) }
  let!(:order_item) { create(:order_item, order: order, product: product) }
  let(:review) { create(:review, user: user, product: product, order: order) }

  before do
    sign_in user
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #new" do
    context "when order is delivered and no existing review" do
      before { get :new, params: { user_id: user.id, order_id: order.id, product_id: product.id } }

      it "renders the new template" do
        expect(response).to render_template(:new)
      end

      it "assigns a new review" do
        expect(assigns(:review)).to be_a_new(Review)
      end
    end

    context "when order is not delivered" do
      before do
        order.update(status: :pending)
        get :new, params: { user_id: user.id, order_id: order.id, product_id: product.id }
      end

      it "redirects to root path" do
        expect(response).to redirect_to(root_path)
      end

      it "sets flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("reviews.must_be_delivered"))
      end
    end

    context "when the user has already reviewed" do
      before do
        create(:review, user: user, order: order, product: product)
        get :new, params: { user_id: user.id, order_id: order.id, product_id: product.id }
      end

      it "redirects to root path" do
        expect(response).to redirect_to(root_path)
      end

      it "sets flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("reviews.already_reviewed"))
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) { { user_id: user.id, order_id: order.id, product_id: product.id, review: attributes_for(:review) } }
    let(:invalid_params) { { user_id: user.id, order_id: order.id, product_id: product.id, review: { rating: nil } } }

    context "with valid parameters" do
      it "creates a new review" do
        expect {
          post :create, params: valid_params
        }.to change(Review, :count).by(1)
      end

      it "sets success flash message" do
        post :create, params: valid_params
        expect(flash[:success]).to eq(I18n.t("reviews.success"))
      end

      it "redirects to order details" do
        post :create, params: valid_params
        expect(response).to redirect_to(user_order_order_details_path(user, order))
      end
    end

    context "with invalid parameters" do
      it "does not create a new review" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Review, :count)
      end

      it "renders new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end

      it "returns unprocessable entity status" do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    let(:update_params) { { user_id: user.id, order_id: order.id, product_id: product.id, id: review.id, review: { rating: 5 } } }

    context "with valid parameters" do
      it "updates the review" do
        patch :update, params: update_params
        review.reload
        expect(review.rating).to eq(5)
      end

      it "sets success flash message" do
        patch :update, params: update_params
        expect(flash[:success]).to eq(I18n.t("reviews.updated"))
      end

      it "redirects to order details" do
        patch :update, params: update_params
        expect(response).to redirect_to(user_order_order_details_path(user, order))
      end
    end

    context "with invalid parameters" do
      let(:invalid_update_params) { { user_id: user.id, order_id: order.id, product_id: product.id, id: review.id, review: { rating: nil } } }

      it "does not update the review" do
        patch :update, params: invalid_update_params
        review.reload
        expect(review.rating).not_to be_nil
      end

      it "renders edit template" do
        patch :update, params: invalid_update_params
        expect(response).to render_template(:edit)
      end

      it "returns unprocessable entity status" do
        patch :update, params: invalid_update_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    before { review }

    it "deletes the review" do
      expect {
        delete :destroy, params: { user_id: user.id, order_id: order.id, product_id: product.id, id: review.id }
      }.to change(Review, :count).by(-1)
    end

    it "sets success flash message" do
      delete :destroy, params: { user_id: user.id, order_id: order.id, product_id: product.id, id: review.id }
      expect(flash[:success]).to eq(I18n.t("reviews.destroyed"))
    end

    it "redirects to order details" do
      delete :destroy, params: { user_id: user.id, order_id: order.id, product_id: product.id, id: review.id }
      expect(response).to redirect_to(user_order_order_details_path(user, order))
    end
  end
end
