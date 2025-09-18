# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/requests/shared/responds.rb")

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard" do
    context "when not logged" do
      before { get "/dashboard" }

      it_behaves_like "respond with redirect"
    end

    context "when logged" do
      let(:account) { create(:account, :verified) }

      before do
        login_user(account)
      end

      it "allows access to dashboard" do
        get "/dashboard"
        expect(response).to have_http_status(:success)
      end

      it "shows user-specific content" do
        get "/dashboard"
        expect(response.body).to include(account.email) # or whatever user-specific content you expect
      end

      # Test that the user is actually logged in by checking rodauth directly
      it "confirms user is logged in via rodauth" do
        get "/dashboard" # Make sure we have a request context
        expect(logged_in?).to be true
      end
    end
  end
end
