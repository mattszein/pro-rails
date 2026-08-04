require "rails_helper"

RSpec.describe Adminit::Dashboard::Accounts::GeneralWidgetComponent, type: :component do
  let(:account) { create(:account, :verified) }

  it "renders the lookup select wired to the account-lookup controller" do
    render_inline(described_class.new(account: account))

    expect(page).to have_css('select[data-controller="account-lookup"]')
    expect(page).to have_css("select[data-account-lookup-search-url-value='/adminit/dashboard/accounts/search']")
  end

  it "passes the summary URL template with an id placeholder" do
    render_inline(described_class.new(account: account))

    expect(page).to have_css("select[data-account-lookup-summary-url-value='/adminit/dashboard/accounts/__id__/summary']")
  end

  it "renders an empty account_summary turbo frame" do
    render_inline(described_class.new(account: account))

    expect(page).to have_css("turbo-frame#account_summary")
  end
end
