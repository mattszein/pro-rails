require "rails_helper"

RSpec.describe Adminit::Dashboard::Accounts::AnalyticsWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }

  before do
    create_list(:account, 2, :verified)
    create(:account)
  end

  it "returns chart options with area type and monthly data" do
    component = described_class.new(account: account)
    options = component.chart_options

    expect(options[:chart][:type]).to eq("area")
    expect(options[:series].first[:data]).to be_an(Array)
    expect(options[:_semanticColors]).to eq(["primary"])
    expect(options[:noData]).to have_key(:text)
  end

  it "renders chart data attributes" do
    render_inline(described_class.new(account: account))
    expect(page).to have_css('[data-controller="chart"]')
    expect(page).to have_css('[data-chart-target="canvas"]')
  end

  it "renders stat summaries alongside chart" do
    render_inline(described_class.new(account: account))
    expect(page).to have_text("3")
    expect(page).to have_text(I18n.t("adminit.dashboard_widgets.accounts.analytics.registered"))
    expect(page).to have_text(I18n.t("adminit.dashboard_widgets.accounts.analytics.active_sessions"))
  end
end
