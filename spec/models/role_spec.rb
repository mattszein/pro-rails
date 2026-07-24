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

  describe ".with_accounts_count" do
    it "returns roles ordered by name with an accounts_count attribute" do
      zeta = create(:role, name: "Zeta")
      alpha = create(:role, name: "Alpha")
      create_list(:account, 2, :verified, role: alpha)

      roles = Role.with_accounts_count.to_a

      expect(roles.map(&:name)).to eq(roles.map(&:name).sort)
      expect(roles.find { |r| r.id == alpha.id }.accounts_count).to eq(2)
      expect(roles.find { |r| r.id == zeta.id }.accounts_count).to eq(0)
    end
  end
end
