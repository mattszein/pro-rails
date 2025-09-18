require "rails_helper"

RSpec.describe Account, type: :model do
  subject(:account) { build(:account, :verified) }

  describe "Associations" do
    it { is_expected.to belong_to(:role).optional }
  end

  describe "Validations (via Rodauth)" do
    it "requires presence of email" do
      expect {
        begin
          create(:account, email: nil)
        rescue
          nil
        end
      }
        .not_to change(Account, :count)
    end

    it "requires uniqueness of email" do
      create(:account, email: "test@example.com")
      expect {
        begin
          create(:account, email: "test@example.com")
        rescue
          nil
        end
      }
        .not_to change(Account, :count)
    end

    it "requires valid email format" do
      expect {
        begin
          create(:account, email: "invalid_email")
        rescue
          nil
        end
      }
        .not_to change(Account, :count)
    end
  end

  describe "Custom logic" do
    it "is valid without a role" do
      account.role = nil
      expect(account).to be_valid
    end

    it "cannot access adminit without a role" do
      account.role = nil
      expect(account.adminit_access?).to be_falsey
    end

    context "with a role" do
      subject(:account) { create(:account, :with_role, :verified) }

      it "can access adminit" do
        expect(account.adminit_access?).to be_truthy
      end
    end
  end
end
