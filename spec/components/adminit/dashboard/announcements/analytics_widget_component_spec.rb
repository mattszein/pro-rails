require "rails_helper"

RSpec.describe Adminit::Dashboard::Announcements::AnalyticsWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }

  before do
    create_list(:announcement, 2, :published)
    create(:announcement, :draft)
    create(:announcement, :scheduled)
  end

  it "renders the widget title" do
    render_inline(described_class.new(account: account))
    expect(page).to have_text(I18n.t("adminit.dashboard_widgets.announcements.analytics.title"))
  end

  it "returns chart options with radial bar type and percentage series" do
    component = described_class.new(account: account)
    options = component.chart_options

    expect(options[:chart][:type]).to eq("radialBar")
    expect(options[:series]).to eq([50, 25, 25])
    expect(options[:_semanticColors]).to eq(["success", "info", "warning"])
    expect(options[:labels].length).to eq(3)
    expect(options[:noData]).to have_key(:text)
  end

  it "renders chart data attributes" do
    render_inline(described_class.new(account: account))
    expect(page).to have_css('[data-controller="chart"]')
    expect(page).to have_css('[data-chart-target="canvas"]')
  end
end
