require "rails_helper"

RSpec.describe Adminit::Accounts::SummaryComponent, type: :component do
  let(:account) { create(:account, :verified) }

  it "renders the account identity fields" do
    render_inline(described_class.new(account: account))

    expect(page).to have_text(account.id.to_s)
    expect(page).to have_text(account.email)
    expect(page).to have_text(I18n.l(account.created_at.to_date, format: :long))
  end

  it "renders the status badge for the account's status" do
    render_inline(described_class.new(account: account))

    expect(page).to have_text(I18n.t("enums.account.status.verified"))
  end

  it "renders a dash when the account has no role" do
    render_inline(described_class.new(account: account))

    expect(page).to have_text("-")
  end

  it "renders the role name when present" do
    role = create(:role, name: "Support Crew")
    account.update!(role: role)

    render_inline(described_class.new(account: account))

    expect(page).to have_text("Support Crew")
  end
end
