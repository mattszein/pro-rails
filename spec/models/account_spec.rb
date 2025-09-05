require "rails_helper"

RSpec.describe Account, type: :model do
  subject {
    create(:account)
  }

  describe "Associations" do
    it { expect(subject).to belong_to(:role).optional }
  end

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is valid with uniq email" do
      create(:account, email: "test@example.com") 
      expect{create(:account, email: "test@example.com")}.to raise_error
    end

    it "is not valid without an email" do
      expect{create(:account, email: nil)}.to raise_error
    end

    it "is not valid with an invalid email" do
      expect {
        create(:account, email: "invalid_email")
      }.to raise_error
    end

    it "is valid without a role" do
      subject.role = nil
      expect(subject).to be_valid
    end

    it "cannot access to adminit without a role" do
      expect(subject.adminit_access?).to be_falsey
    end

    describe "with role" do
      subject {
        create(:account, :role)
      }

      it "can access to adminit" do
        expect(subject.adminit_access?).to be_truthy
      end
    end
  end
end
