require "rails_helper"

RSpec.describe Adminit::Dashboard::Roles::GeneralWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }

  it "renders a table row per role with a link, account count, and permissions" do
    permission = create(:permission, resource: :ticket)
    role = permission.roles.first
    role.update!(name: "Support")
    create(:account, :verified, role: role)
    create(:account, :verified, role: role)

    render_inline(described_class.new(account: account))

    expect(page).to have_link("Support", href: "/adminit/roles/#{role.id}")
    expect(page).to have_css("a[data-turbo-frame='_top']")
    expect(page).to have_css("tbody td", text: "2")
    expect(page).to have_css("tbody td", text: I18n.t("adminit.navigation.tickets"))
  end

  it "shows a dash when a role has no permissions" do
    create(:role, name: "Empty")
    render_inline(described_class.new(account: account))
    expect(page).to have_css("tbody td", text: I18n.t("adminit.dashboard_widgets.roles.no_permissions"))
  end

  it "renders empty state when there are no roles" do
    Role.destroy_all
    render_inline(described_class.new(account: account))
    expect(page).to have_text(I18n.t("adminit.dashboard_widgets.roles.no_roles"))
    expect(page).not_to have_css("table")
  end

  it "renders roles ordered alphabetically" do
    create(:role, name: "Zeta")
    create(:role, name: "Alpha")
    render_inline(described_class.new(account: account))
    rows = page.all("tbody tr")
    expect(rows.first).to have_text("Alpha")
    expect(rows.last).to have_text("Zeta")
  end
end
