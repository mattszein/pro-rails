require "system_helper"

RSpec.describe "Adminit dashboard tabs", type: :system do
  let(:role) { create(:role) }
  let(:account) { create(:account, :verified, role: role) }

  before do
    ticket_permission = create(:permission, resource: :ticket, roles: [role])
    PermissionRole.where(permission_id: ticket_permission.id, role_id: role.id)
      .update_all(dashboard_widget_keys: ["tickets_personal", "tickets_general", "tickets_analytics"])

    login_as(account)
    visit adminit_root_path
  end

  it "switches panels and underline on tab click" do
    expect(page.find('[data-tabs-target="panel"][data-index="0"]')[:class]).not_to include("hidden")
    expect(page.find('[data-tabs-target="panel"][data-index="1"]')[:class]).to include("hidden")

    click_button I18n.t("adminit.dashboard.kinds.general")

    expect(page).to have_css('button[aria-selected="true"]', text: I18n.t("adminit.dashboard.kinds.general"))
    expect(page).to have_css('button[aria-selected="false"]', text: I18n.t("adminit.dashboard.kinds.personal"))

    expect(page.find('[data-tabs-target="panel"][data-index="0"]')[:class]).to include("hidden")
    expect(page.find('[data-tabs-target="panel"][data-index="1"]')[:class]).not_to include("hidden")
  end

  it "preserves lazy turbo frames with auto-refresh data" do
    frame = page.find("turbo-frame#dashboard_tickets_personal")

    expect(frame["src"]).to eq(adminit_dashboard_widget_path(key: "tickets_personal"))
    expect(frame["data-controller"]).to eq("auto-refresh")
    expect(frame["data-auto-refresh-interval-value"]).to eq("30")
  end
end
