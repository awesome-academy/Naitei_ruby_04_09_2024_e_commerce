require "rails_helper"

RSpec.describe AddressesController, type: :controller do
  let(:user) { create(:user) }
  let(:address) { create(:address, user: user) }

  before do
    sign_in user 
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:admin?).and_return(false)
  end

  describe "GET #index" do
    let!(:default_address) { create(:address, user: user, default: true) }
    let!(:not_default_address) { create(:address, user: user, default: false) }

    before { get :index, params: { user_id: user.id } }

    it "assigns @default_address" do
      expect(assigns(:default_address)).to eq([default_address])
    end

    it "assigns @addresses" do
      expect(assigns(:addresses)).to include(not_default_address)
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  describe "GET #new" do
    before { get :new, params: { user_id: user.id } }

    it "assigns a new @address" do
      expect(assigns(:address)).to be_a_new(Address)
    end

    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      before do
        post :create, params: { user_id: user.id, address: attributes_for(:address, default: true) }
      end

      it "creates a new address" do
        expect {
          post :create, params: { user_id: user.id, address: attributes_for(:address, default: true) }
        }.to change(Address, :count).by(1)
      end

      it "redirects to the addresses index" do
        expect(response).to redirect_to(user_addresses_path(user))
      end
    end

    context "with invalid attributes" do
      before do
        post :create, params: { user_id: user.id, address: attributes_for(:address, receiver_name: nil) }
      end

      it "does not save the new address" do
        expect {
          post :create, params: { user_id: user.id, address: attributes_for(:address, receiver_name: nil) }
        }.not_to change(Address, :count)
      end

      it "re-renders the new template" do
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #edit" do
    before { get :edit, params: { user_id: user.id, id: address.id } }

    it "assigns the requested address" do
      expect(assigns(:address)).to eq(address)
    end

    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    context "with valid attributes" do
      before do
        patch :update, params: { user_id: user.id, id: address.id, address: { receiver_name: "New Name" } }
      end

      it "updates the address" do
        address.reload
        expect(address.receiver_name).to eq("New Name")
      end

      it "redirects to the addresses index" do
        expect(response).to redirect_to(user_addresses_path(user))
      end
    end

    context "with invalid attributes" do
      before do
        patch :update, params: { user_id: user.id, id: address.id, address: { receiver_name: nil } }
      end

      it "does not update the address" do
        address.reload
        expect(address.receiver_name).not_to be_nil
      end

      it "re-renders the edit template" do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:address_to_delete) { create(:address, user: user) }

    it "deletes the address" do
      expect {
        delete :destroy, params: { user_id: user.id, id: address_to_delete.id }
      }.to change(Address, :count).by(-1)
    end

    it "redirects to addresses index" do
      delete :destroy, params: { user_id: user.id, id: address_to_delete.id }
      expect(response).to redirect_to(user_addresses_path(user))
    end
  end
end
