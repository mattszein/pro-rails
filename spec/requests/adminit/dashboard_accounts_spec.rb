# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adminit dashboard accounts", type: :request do
  let(:role) { create(:role) }
  let(:account) { create(:account, :verified, role: role) }

  before do
    create(:permission, resource: :account, roles: [role])
    login_user(account)
  end

  describe "GET /adminit/dashboard/accounts/:id/summary" do
    let(:target) { create(:account, :verified) }

    it "renders the account summary inside the turbo frame" do
      get "/adminit/dashboard/accounts/#{target.id}/summary", headers: {"Turbo-Frame" => "account_summary"}

      expect(response).to have_http_status(:success)
      expect(response.body).to include('turbo-frame id="account_summary"')
      expect(response.body).to include(target.email)
      expect(response.body).to include(I18n.t("adminit.dashboard_widgets.accounts.general.view_full"))
    end

    it "redirects non-frame requests to root" do
      get "/adminit/dashboard/accounts/#{target.id}/summary"

      expect(response).to redirect_to(root_url)
    end
  end
end
