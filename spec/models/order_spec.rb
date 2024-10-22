require "rails_helper"

RSpec.describe Order, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:address) }
    it { should have_many(:order_items).dependent(:destroy) }
    it { should have_many(:products).through(:order_items) }
  end

  describe "validations" do
    let(:order) { build(:order) }

    describe "total" do
      it "validates presence of total" do
        expect(order).to validate_presence_of(:total)
      end
      
      it "validates numericality of total" do
        expect(order).to validate_numericality_of(:total).is_greater_than_or_equal_to(0)
      end
    end
    
    describe "status" do
      it "validates presence of status" do
        expect(order).to validate_presence_of(:status)
      end

      context "when order is cancelled" do
        subject { build(:order, status: :cancelled) }

        it "validates presence of cancel_reason" do
          expect(subject).to validate_presence_of(:cancel_reason)
        end
      end

      context "when order is not cancelled" do
        subject { build(:order, status: :pending) }

        it "does not validate presence of cancel_reason" do
          expect(subject).not_to validate_presence_of(:cancel_reason)
        end           
      end 
    end 
  end

  describe "scopes" do
    let!(:order1) { create(:order, status: "delivered", total: 100.0) }
    let!(:order2) { create(:order, status: "pending", total: 50.0) }
    let!(:order3) { create(:order, status: "cancelled", total: 30.0, cancel_reason: "Customer request") }

    describe ".ordered_by_updated_at" do
      it "returns orders sorted by updated_at descending" do
        expect(Order.ordered_by_updated_at).to eq([order3, order2, order1])
      end
    end

    describe ".by_status" do
      it "returns orders with the specified status" do
        expect(Order.by_status("delivered")).to include(order1)
      end

      it "does not return orders with a different status" do
        expect(Order.by_status("delivered")).not_to include(order2)
      end
    end

    describe ".total_revenue" do
      it "calculates the total revenue for delivered orders" do
        expect(Order.total_revenue).to eq(100.0)
      end
    end

    describe ".with_status" do
      it "returns orders with a valid status" do
        expect(Order.with_status("cancelled")).to include(order3)
      end

      it "returns orders with a pending status" do
        expect(Order.with_status("pending")).to include(order2)
      end

      it "returns orders with a delivered status" do
        expect(Order.with_status("delivered")).to include(order1)
      end
    end

    describe ".created_at_month" do
      let(:month) { Time.current.beginning_of_month }

      it "returns orders created within a specific month" do
        expect(Order.created_at_month(month)).to include(order1, order2, order3)
      end
    end
  end

  describe Order do
    describe "#send_order_notification" do
      let(:order) { create(:order, status: "pending") }

      it "creates a notification after the order is created" do
        expect { order.save }.to change(Notification, :count).by(2)
      end
    end

    describe ".cal_sum_orders" do
      let!(:order1) { create(:order, total: 50, status: "delivered") }
      let!(:order2) { create(:order, total: 100, status: "delivered") }

      it "calculates the sum of the orders" do
        expect(Order.cal_sum_orders(Order.all)).to eq(150)
      end
    end
  end 
end
