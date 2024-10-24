require "rails_helper"

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:cart) { create(:cart, user: user) }
  let(:cart_item) { create(:cart_item, cart: cart, product: product) }
  let!(:address) { create(:address, user: user) }
  let!(:order) { create(:order, user: user, address: address, status: "pending") }
  let!(:order_item) { create(:order_item, order: order, product: product) }
  
  before do
    sign_in user 
    allow(controller).to receive(:current_cart_items).and_return([cart_item])
  end

  describe "GET #new" do
    before do
      get :new
    end
    it "initializes a new order" do
      expect(assigns(:order)).to be_a_new(Order)
    end
    
    it "calculates the order total correctly" do
      expect(assigns(:order).total).to eq(cart_item.quantity * product.price)
    end
    
    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      before do
        post :create, params: {
          order: { address_id: address.id }
        }
      end
      it "creates a new order" do
        expect(assigns(:order)).to be_persisted
      end
      
      it "sets the order total correctly" do
        expect(assigns(:order).total).to eq(cart_item.quantity * product.price)
      end
      
      it "redirects to the order show page" do
        expect(response).to redirect_to(order_path(assigns(:order)))
      end
    end

    context "with invalid attributes" do
      before do
        post :create, params: {
          order: { address_id: nil }
        }
      end
      it "renders the new template with errors" do
        allow_any_instance_of(Order).to receive(:save).and_return(false)
        expect(response).to render_template(:new)
      end
      
      it "displays an error message" do
        allow_any_instance_of(Order).to receive(:save).and_return(false)
        expect(flash.now[:alert]).to eq(I18n.t("orders.create.order_fail"))
      end
    end
  end

  describe "GET #show" do
    context "when the order is found" do
      before do
        get :show, params: { id: order.id }
      end
      it "assigns the requested order to @order" do
        expect(assigns(:order)).to eq(order)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end

    context "when the order is not found" do
      before do
        get :show, params: { id: "invalid_id" }
      end
      it "displays flash alert" do
        expect(flash[:alert]).to eq(I18n.t("orders.not_found_order"))
      end

      it "redirects to root_path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #index" do
    before do
      get :index, params: { user_id: user.id, status: "pending" }
    end
    it "paginates and displays user orders" do
      expect(assigns(:orders)).to eq(user.orders.where(status: "pending"))
    end

    it "assigns a pagy object" do
      expect(assigns(:pagy)).not_to be_nil
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  describe "GET #order_details" do
    context "when the order exists" do
      before do
        get :order_details, params: { user_id: user.id, order_id: order.id }
      end
      it "assigns the order items" do
        expect(assigns(:order)).to eq(order)
      end

      it "assigns the order items" do
        expect(assigns(:order_items)).to eq(order.order_items)
      end

      it "renders the order_details partial" do
        expect(response).to render_template("orders/_order_details")
      end
    end

    context "when the order does not exist" do
      before { get :order_details, params: { user_id: user.id, order_id: 9999 } }
    
      it "sets a flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("orders.not_found_order"))
      end
    
      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #cancel" do
    context "when order is pending and cancel reason is present" do
      before do
        post :cancel, params: { user_id: user.id, id: order.id, order: { cancel_reason: "Changed my mind" } }
      end
      it "updates order to cancelled" do
        order.reload
        expect(order.status).to eq("cancelled")
      end

      it "restores the product stock" do
        order.reload
        expect(product.reload.stock).to eq(3)
      end

      it "displays a success message" do
        expect(flash[:success]).to eq(I18n.t("orders.cancel.order_canceled"))
      end

      it "redirects to the order details page" do
        expect(response).to redirect_to(user_order_order_details_path(user, order))
      end
    end

    context "when cancel reason is missing" do
      before do
        post :cancel, params: { user_id: user.id, id: order.id, order: { cancel_reason: nil } }
      end
      it "fails to cancel the order" do
        order.reload
        expect(order.status).not_to eq("cancelled")
      end

      it "displays an error message" do
        expect(flash[:danger]).to eq(I18n.t("orders.cancel.cancel_failed"))
      end

      it "redirects to the order details page" do
        expect(response).to redirect_to(user_order_order_details_path(user, order))
      end
    end

    context "when order is not pending" do
      before do
        order.update(status: "delivered")
        post :cancel, params: { user_id: user.id, id: order.id, order: { cancel_reason: "Late delivery" } }
      end
      it "cannot cancel a non-pending order" do
        order.reload
        expect(order.status).to eq("delivered")
      end

      it "displays an error message" do
        expect(flash[:danger]).to eq(I18n.t("orders.cancel.cannot_cancel_order"))
      end

      it "redirects to the order details page" do
        expect(response).to redirect_to(user_order_order_details_path(user, order))
      end
    end
  end
end
