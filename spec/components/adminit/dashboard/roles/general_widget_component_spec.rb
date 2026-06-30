require "rails_helper"

RSpec.describe Adminit::Dashboard::Roles::GeneralWidgetComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:account) { create(:account, :verified) }

  before do
    create(:role, name: "Admin")
    create(:role, name: "Support")
  end

  it "renders the widget title" do
    render_inline(described_class.new(account: account))
    expect(page).to have_text(I18n.t("adminit.dashboard_widgets.roles.general.title"))
  end

  it "renders links to each role that break out of the turbo frame" do
    render_inline(described_class.new(account: account))
    admin_role = Role.find_by(name: "Admin")
    support_role = Role.find_by(name: "Support")
    expect(page).to have_link("Admin", href: "/adminit/roles/#{admin_role.id}")
    expect(page).to have_link("Support", href: "/adminit/roles/#{support_role.id}")
    expect(page).to have_css("a[data-turbo-frame='_top']", count: 2)
  end

  it "renders empty state when there are no roles" do
    Role.destroy_all
    render_inline(described_class.new(account: account))
    expect(page).to have_text(I18n.t("adminit.dashboard_widgets.roles.no_roles"))
  end
end
