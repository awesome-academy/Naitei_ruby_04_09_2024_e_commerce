require "rails_helper"

RSpec.describe CartsController, type: :controller do
  let(:user) { create(:user) }
  let(:product) { create(:product) } 
  let(:cart) { create(:cart, user: user) }

  before do
    sign_in user  
    cart 
  end

  describe "GET #show" do
    context "when cart exists" do
      it "renders the show template" do
        get :show, params: { id: cart.id }
        expect(response).to render_template(:show)
      end
    end

    context "when cart does not exist" do
      it "redirects to root path with an error message" do
        get :show, params: { id: 999 }
        expect(flash[:danger]).to eq(I18n.t("carts.cart_not_found"))
        expect(response).to redirect_to(root_path)
      end
    end

        context "when product does not exist" do
      it "redirects to root path with an error message" do
        post :add_item, params: { product_id: 999, quantity: 1 }
        expect(flash[:danger]).to eq(I18n.t("carts.product_not_found"))
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #add_item" do
    context "when item stock is sufficient" do
      it "creates a new cart item" do
        expect {
          post :add_item, params: { product_id: product.id, quantity: 1 }
        }.to change { cart.cart_items.count }.by(1)

        expect(flash.now[:success]).to eq(I18n.t("carts.item_added_success"))
      end
    end

    context "when item stock is insufficient" do
      before do
        product.update(stock: 0)
      end

      it "does not create a new cart item" do
        expect {
          post :add_item, params: { product_id: product.id, quantity: 1 }
        }.not_to change { cart.cart_items.count }

        expect(flash.now[:error]).to eq(I18n.t("carts.insufficient_stock"))
      end
    end
  end

  describe "PATCH #increment_item" do
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

    context "when stock is sufficient" do
      it "increments the cart item quantity" do
        expect {
          patch :increment_item, params: { id: cart_item.id }
        }.to change { cart_item.reload.quantity }.by(1)

        expect(flash.now[:success]).to eq(I18n.t("carts.item_increment_success"))
      end
    end

    context "when stock is insufficient" do
      before do
        product.update(stock: 0)
      end

      it "does not increment the cart item quantity" do
        patch :increment_item, params: { id: cart_item.id }

        expect(flash.now[:error]).to eq(I18n.t("carts.insufficient_stock"))
      end
    end

    context "when cart item does not exist" do
      it "redirects to cart path with error message" do
        patch :increment_item, params: { id: 999 }

        expect(flash[:danger]).to eq(I18n.t("carts.cart_item_not_found"))
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH #decrement_item" do
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2) }

    it "decrements the cart item quantity" do
      expect {
        patch :decrement_item, params: { id: cart_item.id }
      }.to change { cart_item.reload.quantity }.by(-1)

      expect(flash.now[:success]).to eq(I18n.t("carts.item_decrement_success"))
    end

    context "when quantity is 1" do
      before do
        cart_item.update(quantity: 1)
      end

      it "removes the cart item" do
        expect {
          patch :decrement_item, params: { id: cart_item.id }
        }.to change { cart.cart_items.count }.by(-1)

        expect(flash.now[:success]).to eq(I18n.t("carts.item_removed_success"))
      end
    end

    context "when cart item does not exist" do
      it "redirects to cart path with error message" do
        patch :decrement_item, params: { id: 999 }

        expect(flash[:danger]).to eq(I18n.t("carts.cart_item_not_found"))
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE #remove_item" do
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

    it "removes the cart item" do
      expect {
        delete :remove_item, params: { id: cart_item.id }
      }.to change { cart.cart_items.count }.by(-1)

      expect(flash.now[:success]).to eq(I18n.t("carts.item_removed_success"))
    end

    it "redirects to the cart path" do
      delete :remove_item, params: { id: cart_item.id }
      expect(response).to redirect_to(cart_path(cart))
    end

    it "does not raise an error if cart item does not exist" do
      delete :remove_item, params: { id: 999 }

      expect(flash[:danger]).to eq(I18n.t("carts.cart_item_not_found"))
      expect(response).to redirect_to(root_path)
    end
  end
end
