require "rails_helper"

RSpec.describe Adminit::Dashboard::Announcements::GeneralWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }

  it "renders scheduled announcements as a list ordered by scheduled_at asc" do
    create(:announcement, :scheduled, scheduled_at: 2.days.from_now, title: "Later")
    create(:announcement, :scheduled, scheduled_at: 1.day.from_now, title: "Sooner")

    render_inline(described_class.new(account: account))

    items = page.all("li")
    expect(items.size).to eq(2)
    expect(items.first).to have_text("Sooner")
    expect(items.last).to have_text("Later")
  end

  it "does not include draft, published, or past-due scheduled announcements" do
    create(:announcement, :scheduled, title: "Scheduled One")
    create(:announcement, title: "Draft One")
    past_due = create(:announcement, :scheduled, title: "Past Due")
    past_due.update_column(:scheduled_at, 1.hour.ago)

    render_inline(described_class.new(account: account))

    expect(page).to have_text("Scheduled One")
    expect(page).not_to have_text("Draft One")
    expect(page).not_to have_text("Past Due")
  end

  it "renders a link to each announcement" do
    ann = create(:announcement, :scheduled, title: "My Ann")
    render_inline(described_class.new(account: account))
    expect(page).to have_link("My Ann", href: "/adminit/announcements/#{ann.id}")
  end

  it "renders the scheduled_at date next to each entry" do
    scheduled_at = 3.days.from_now
    create(:announcement, :scheduled, scheduled_at: scheduled_at, title: "Future")
    render_inline(described_class.new(account: account))
    expect(page).to have_css("li", text: I18n.l(scheduled_at, format: :long))
  end

  it "renders an empty state when there are no scheduled announcements" do
    render_inline(described_class.new(account: account))
    expect(page).to have_text(I18n.t("shared.empty"))
    expect(page).not_to have_css("ul li")
  end

  it "renders a list heading for the scheduled list" do
    render_inline(described_class.new(account: account))
    expect(page).to have_css("h5", text: I18n.t("adminit.dashboard_widgets.announcements.general.list_title"))
  end

  describe "chart" do
    before do
      create_list(:announcement, 2, :published)
      create(:announcement, :draft)
      create(:announcement, :scheduled)
    end

    it "returns chart options with radial bar type and percentage series" do
      component = described_class.new(account: account)
      options = component.chart_options

      expect(options[:chart][:type]).to eq("radialBar")
      expect(options[:series]).to eq([50, 25, 25])
      expect(options[:_semanticColors]).to eq(["success", "info", "warning"])
      expect(options[:labels].length).to eq(3)
    end

    it "renders chart data attributes" do
      render_inline(described_class.new(account: account))
      expect(page).to have_css('[data-controller="chart"]')
      expect(page).to have_css('[data-chart-target="canvas"]')
    end
  end
end
