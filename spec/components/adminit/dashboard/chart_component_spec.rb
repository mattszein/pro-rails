require "rails_helper"

RSpec.describe Adminit::Dashboard::ChartComponent, type: :component do
  it "wires the chart Stimulus controller with the given options" do
    options = Dashboard::ChartOptions.donut(labels: ["A"], series: [1], semantic_colors: ["primary"])
    render_inline(described_class.new(options: options))

    root = page.find("[data-controller='chart']")
    expect(root["data-chart-height-value"]).to eq(Adminit::DashboardHelper::CHART_HEIGHT.to_s)
    expect(JSON.parse(root["data-chart-options-value"])["labels"]).to eq(["A"])
  end

  it "accepts a custom height" do
    options = Dashboard::ChartOptions.donut(labels: [], series: [], semantic_colors: [])
    render_inline(described_class.new(options: options, height: 400))

    expect(page.find("[data-controller='chart']")["data-chart-height-value"]).to eq("400")
  end

  it "renders the canvas target for ApexCharts to mount into" do
    options = Dashboard::ChartOptions.donut(labels: [], series: [], semantic_colors: [])
    render_inline(described_class.new(options: options))

    expect(page).to have_css("[data-chart-target='canvas']")
  end
end
