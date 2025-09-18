# spec/models/role_spec.rb

require "rails_helper"

RSpec.describe Role, type: :model do
  subject {
    create(:role)
  }

  describe "Associations" do
    it { expect(subject).to have_many(:accounts) }
  end

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a name" do
      subject.name = nil
      expect(subject).to_not be_valid
    end
  end
end
