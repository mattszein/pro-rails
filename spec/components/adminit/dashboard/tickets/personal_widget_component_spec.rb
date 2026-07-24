require "rails_helper"

RSpec.describe Adminit::Dashboard::Tickets::PersonalWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }

  it "renders only open tickets assigned to the account" do
    create(:ticket, title: "Mine", assigned: account)
    create(:ticket, title: "Not mine", assigned: other_account)

    render_inline(described_class.new(account: account))

    expect(page).to have_text("Mine")
    expect(page).not_to have_text("Not mine")
  end

  it "renders a table with a title link and status badge" do
    ticket = create(:ticket, assigned: account)

    render_inline(described_class.new(account: account))

    expect(page).to have_link(ticket.title, href: "/adminit/tickets/#{ticket.id}")
    expect(page).to have_css("tbody td", text: I18n.t("enums.ticket.status.open"))
  end

  it "does not include closed assigned tickets" do
    create(:ticket, :closed, title: "Done long ago", assigned: account)

    render_inline(described_class.new(account: account))

    expect(page).not_to have_text("Done long ago")
  end

  it "renders empty state when nothing is assigned" do
    render_inline(described_class.new(account: account))
    expect(page).to have_text(I18n.t("shared.empty"))
    expect(page).not_to have_css("table")
  end
end
