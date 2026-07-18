require "rails_helper"

RSpec.describe Adminit::Dashboard::Tickets::AnalyticsWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }

  before do
    create_list(:ticket, 3, status: :open)
    create(:ticket, :closed)
  end

  it "returns chart options with column type and status data" do
    component = described_class.new(account: account)
    options = component.chart_options

    expect(options[:chart][:type]).to eq("bar")
    expect(options[:plotOptions][:bar]).to include(distributed: true)
    expect(options[:series].first[:data]).to include(3)
    expect(options[:_semanticColors]).to be_an(Array)
    expect(options[:noData]).to have_key(:text)
  end

  it "renders chart data attributes" do
    render_inline(described_class.new(account: account))
    expect(page).to have_css('[data-controller="chart"]')
    expect(page).to have_css('[data-chart-target="canvas"]')
  end

  it "renders stat summaries alongside chart" do
    render_inline(described_class.new(account: account))
    expect(page).to have_text("4")
    expect(page).to have_text("3")
    expect(page).to have_text(I18n.t("adminit.dashboard_widgets.tickets.analytics.resolved"))
  end
end
