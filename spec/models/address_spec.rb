require "rails_helper"

RSpec.describe Address, type: :model do
  let(:user) { create(:user) }
  let(:address) { create(:address, user: user) }

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    describe "receiver_name" do
      it { should validate_presence_of(:receiver_name) }
      it { should validate_length_of(:receiver_name).is_at_most(Settings.value.max_receiver_name) }
    end

    describe "place" do
      it { should validate_presence_of(:place) }
      it { should validate_length_of(:place).is_at_most(Settings.value.max_place_length) }
    end

    describe "phone" do
      it { should validate_presence_of(:phone) }
      it { should allow_value("0123456789").for(:phone) }
      it { should_not allow_value("12345abcde").for(:phone) }
      it { should_not allow_value("123").for(:phone) }
    end
  end

  describe "scopes" do
    let!(:default_address) { create(:address, user: user, default: true) }
    let!(:not_default_address) { create(:address, user: user, default: false) }
    
    describe ".ordered_by_updated_at" do
      it "returns addresses ordered by updated_at in descending order" do
        address.update(updated_at: Time.current + 1.day)
        expect(Address.ordered_by_updated_at.first).to eq(address)
      end
    end

    describe ".default_address" do
      it "returns addresses marked as default" do
        expect(Address.default_address).to include(default_address)
      end
  
      it "does not include addresses that are not marked as default" do
        expect(Address.default_address).not_to include(not_default_address)
      end
    end
  
    describe ".not_default_address" do
      it "returns addresses that are not marked as default" do
        expect(Address.not_default_address).to include(not_default_address)
      end
  
      it "does not include addresses that are marked as default" do
        expect(Address.not_default_address).not_to include(default_address)
      end
    end
  end

  describe "class methods" do
    describe ".set_default_false" do
      let!(:address1) { create(:address, user: user, default: true) }
      let!(:address2) { create(:address, user: user, default: false) }

      it "sets all user addresses default to false" do
        Address.set_default_false(user)
        expect(user.addresses.pluck(:default)).to all(be_falsey)
      end
    end
  end 

  describe "instance methods" do
    describe "#full_address" do
      it "returns the full address in the correct format" do
        expected_string = I18n.t("address.full_address", receiver_name: address.receiver_name, place: address.place, phone: address.phone)
        expect(address.full_address).to eq(expected_string)
      end
    end
  end
end
