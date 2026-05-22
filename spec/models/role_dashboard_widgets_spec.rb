require "rails_helper"

RSpec.describe Role, type: :model do
  describe "#dashboard_widgets" do
    let(:role) { create(:role) }
    let(:ticket_permission) { create(:permission, resource: :ticket, roles: [role]) }

    it "returns empty array when no widgets are configured" do
      expect(role.dashboard_widgets).to be_empty
    end

    it "returns widgets enabled for the role" do
      PermissionRole.where(permission_id: ticket_permission.id, role_id: role.id)
        .update_all(dashboard_widget_keys: ["tickets_personal", "tickets_general"])

      widgets = role.dashboard_widgets
      expect(widgets.map(&:key)).to contain_exactly(:tickets_personal, :tickets_general)
    end
  end
end
