require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { should have_many(:products).dependent(:nullify) }
  end

  describe "validations" do
    let(:category) { build(:category) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_length_of(:name).is_at_most(Settings.value.max_category_name) }
  end

  describe "scopes" do
    let!(:category1) { create(:category, name: "Manga") }
    let!(:category2) { create(:category, name: "Novel") }

    describe ".by_name" do
      it "returns categories matching the name" do
        expect(Category.by_name("Manga")).to include(category1)
      end

      it "does not return categories not matching the name" do
        expect(Category.by_name("Manga")).not_to include(category2)
      end
    end

    describe ".sorted" do
      it "returns categories sorted by name in ascending order" do
        expect(Category.sorted("name", "asc")).to eq([category1, category2])
      end

      it "returns categories sorted by created_at in ascending order" do
        expect(Category.sorted("created_at", "asc")).to eq([category1, category2])
      end
    end

    describe ".with_product_count" do
      it "returns categories with product count" do
        category1.products << create(:product)
        expect(Category.with_product_count.first.products_count).to eq(1)
      end
    end
  end

  describe Category do
    describe "#products_count" do
      it "returns the correct product count" do
        category = create(:category)
        category.products << create(:product)
        expect(category.products_count).to eq(1)
      end
    end
  end
end
