require "rails_helper"

RSpec.describe RolesListQuery do
  describe ".call" do
    it "returns roles ordered by name" do
      create(:role, name: "Zeta")
      create(:role, name: "Alpha")

      roles = described_class.call

      expect(roles.map(&:name)).to eq(["Alpha", "Zeta"])
    end
  end
end
