require "rails_helper"

RSpec.describe Cart, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:cart_items).dependent(:destroy) }
  end
end
