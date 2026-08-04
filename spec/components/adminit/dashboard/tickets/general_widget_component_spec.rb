require "rails_helper"

RSpec.describe Adminit::Dashboard::Tickets::GeneralWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }

  it "renders a table row per open ticket with a title link and status badge" do
    ticket = create(:ticket, title: "Login broken")

    render_inline(described_class.new(account: account))

    expect(page).to have_link("Login broken", href: "/adminit/tickets/#{ticket.id}")
    expect(page).to have_css("tbody td", text: I18n.t("enums.ticket.status.open"))
  end

  # Widgets render inside lazy turbo frames — links must break out of the
  # frame or navigation would load inside the widget. This is the single
  # guard for that contract (see PLAN.md O38).
  it "renders links that break out of the turbo frame" do
    create(:ticket)
    render_inline(described_class.new(account: account))
    expect(page).to have_css("tbody a[data-turbo-frame='_top']")
  end

  it "does not include closed tickets" do
    create(:ticket, title: "Still open")
    create(:ticket, :closed, title: "Long closed")

    render_inline(described_class.new(account: account))

    expect(page).to have_text("Still open")
    expect(page).not_to have_text("Long closed")
  end

  it "renders empty state when there are no open tickets" do
    render_inline(described_class.new(account: account))
    expect(page).to have_text(I18n.t("shared.table.empty"))
  end
end
