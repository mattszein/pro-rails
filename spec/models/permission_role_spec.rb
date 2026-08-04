require "rails_helper"

RSpec.describe PermissionRole, type: :model do
  let(:role) { create(:role) }
  let(:permission) { create(:permission, resource: :ticket, roles: [role]) }
  let(:permission_role) { PermissionRole.find_by(permission_id: permission.id, role_id: role.id) }

  describe "validations" do
    context "with valid widget keys" do
      it "is valid" do
        permission_role.dashboard_widget_keys = ["tickets_personal"]
        expect(permission_role).to be_valid
      end
    end

    context "with unknown widget keys" do
      it "is not valid" do
        permission_role.dashboard_widget_keys = ["unknown_widget"]
        expect(permission_role).not_to be_valid
        expect(permission_role.errors[:dashboard_widget_keys]).to include(/contains unknown widget keys/)
      end
    end

    context "with widget keys that do not match permission resource" do
      it "is not valid" do
        permission_role.dashboard_widget_keys = ["announcements_general"]
        expect(permission_role).not_to be_valid
        expect(permission_role.errors[:dashboard_widget_keys]).to include(/contains widget keys not matching the permission's resource/)
      end
    end
  end

  describe "#enabled_widgets" do
    it "returns widgets for the enabled keys" do
      permission_role.update_column(:dashboard_widget_keys, ["tickets_personal", "tickets_general"])
      widgets = permission_role.enabled_widgets
      expect(widgets.map(&:key)).to contain_exactly(:tickets_personal, :tickets_general)
    end
  end
end
