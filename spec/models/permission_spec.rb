require "rails_helper"

RSpec.describe Permission, type: :model do
  subject {
    create(:permission)
  }
  describe "Associations" do
    it { should have_and_belong_to_many(:roles) }
  end

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a resource name" do
      subject.resource = nil
      expect(subject).to_not be_valid
    end

    it "is not valid without roles" do
      subject.roles.clear  # Remove all associated roles
      expect(subject).to_not be_valid
    end
  end

  describe "class methods" do
    it "has a default" do
      expect(subject.class.default).to be_valid
    end
  end
end
