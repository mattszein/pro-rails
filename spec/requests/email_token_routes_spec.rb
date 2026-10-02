# spec/requests/email_token_routes_spec.rb
require "rails_helper"

# RodauthApp runs `rodauth.load_memory` before every route. With `extend_remember_deadline?` that
# loads the account from the session once the last extension is older than an hour, right before
# an email-token route loads the same account by key. Rodauth 2.47+ guards against reloading an
# account with a different retrieval type inside one request, so this must keep working.
describe "Email-token routes after the remember extension is stale", type: :request do
  include ActiveJob::TestHelper

  let(:account) { create(:account, :verified) }
  let(:new_email) { "changed@#{TestConstants::TEST_EMAIL_DOMAIN}" }

  def request_login_change
    ActionMailer::Base.deliveries.clear
    perform_enqueued_jobs do
      post "/change-login", params: {
        email: new_email,
        "email-confirm": new_email,
        password: TestConstants::TEST_PASSWORD
      }
    end
    ActionMailer::Base.deliveries.last.body.to_s[/verify-login-change\?key=([^\s"&<]+)/, 1]
  end

  def verify_login_change(key)
    get "/verify-login-change", params: {key: key}
    follow_redirect! if response.redirect?
    post "/verify-login-change", params: {key: key}
  end

  describe "verifying a login change" do
    before { login_user(account) }

    it "confirms the new email when the link is opened right away" do
      key = request_login_change
      expect(key).to be_present

      verify_login_change(key)

      expect(account.reload.email).to eq(new_email)
    end

    it "confirms the new email when the link is opened after the remember extension is stale" do
      key = request_login_change
      expect(key).to be_present

      travel 2.hours do
        verify_login_change(key)

        expect(response).not_to have_http_status(:internal_server_error)
        expect(account.reload.email).to eq(new_email)
      end
    end
  end
end
