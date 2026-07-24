require "rails_helper"

RSpec.describe Adminit::Dashboard::TabbedContainerComponent, type: :component do
  def widget_for(key)
    Dashboard::WidgetRegistry.find(key)
  end

  it "always renders tabs, even for a single-widget resource" do
    render_inline(described_class.new(resource: :role, widgets: [widget_for(:roles_general)]))

    expect(page).to have_css('[role="tablist"]')
    expect(page).to have_css('[role="tab"]', count: 1)
    expect(page).to have_css('[role="tabpanel"]', count: 1)
  end

  it "renders one tab per widget with translated labels" do
    widgets = %i[tickets_personal tickets_general tickets_analytics].map { |k| widget_for(k) }
    render_inline(described_class.new(resource: :ticket, widgets: widgets))

    expect(page).to have_css('[role="tab"]', count: 3)
    expect(page).to have_css('[role="tab"]', text: I18n.t("adminit.dashboard.kinds.personal"))
    expect(page).to have_css('[role="tab"]', text: I18n.t("adminit.dashboard.kinds.general"))
    expect(page).to have_css('[role="tab"]', text: I18n.t("adminit.dashboard.kinds.analytics"))
  end

  it "renders the resource title" do
    render_inline(described_class.new(resource: :role, widgets: [widget_for(:roles_general)]))
    expect(page).to have_css("h4", text: I18n.t("adminit.navigation.roles"))
  end

  it "derives the view-all link from the resource index route" do
    render_inline(described_class.new(resource: :role, widgets: [widget_for(:roles_general)]))
    expect(page).to have_link(I18n.t("shared.common.view_all"), href: "/adminit/roles")
  end

  it "gives each tab its own view-all link, from that widget's view_all_params" do
    widgets = %i[tickets_personal tickets_general].map { |k| widget_for(k) }
    render_inline(described_class.new(resource: :ticket, widgets: widgets))

    links = page.all("a", text: I18n.t("shared.common.view_all"), visible: :all)
    hrefs = links.pluck(:href)
    expect(hrefs).to include("/adminit/tickets?assignee=me", "/adminit/tickets")
  end

  it "renders stable ARIA ids that don't depend on object identity" do
    render_inline(described_class.new(resource: :role, widgets: [widget_for(:roles_general)]))
    render_inline(described_class.new(resource: :role, widgets: [widget_for(:roles_general)]))

    expect(page).to have_css('[role="tab"][id="dashboard-role-tabs-tab-0"]')
  end
end
