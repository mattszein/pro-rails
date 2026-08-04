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

  describe ".assignable" do
    it "returns accounts with a role, ordered by email" do
      with_role_b = create(:account, :with_role, :verified, email: "bbb@example.com")
      with_role_a = create(:account, :with_role, :verified, email: "aaa@example.com")
      create(:account, :verified, email: "no_role@example.com")

      expect(Account.assignable).to eq([with_role_a, with_role_b])
    end
  end

  describe ".dashboard_stats" do
    it "returns account stats" do
      create_list(:account, 2, :verified)
      create(:account)
      verified_account = Account.verified.first
      AccountRememberKey.create!(id: verified_account.id, key: "secret", deadline: 1.week.from_now)

      stats = Account.dashboard_stats

      expect(stats[:total]).to eq(3)
      expect(stats[:verified]).to eq(2)
      expect(stats[:active_sessions]).to eq(1)
      expect(stats[:registered_this_month]).to eq(3)
      expect(stats[:by_month]).to be_a(Hash)
      expect(stats[:by_month].values).to include(3)
    end
  end
end
