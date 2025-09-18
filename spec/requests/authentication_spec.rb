# spec/requests/authentication_spec.rb
require "rails_helper"
require "nokogiri"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe "Authentication Routes", type: :request do
  include ActiveJob::TestHelper

  describe "POST /create-account" do
    let(:valid_account_params) do
      {
        email: "user@#{TestConstants::TEST_EMAIL_DOMAIN}",
        password: TestConstants::TEST_PASSWORD,
        "password-confirm": TestConstants::TEST_PASSWORD
      }
    end

    let(:invalid_email_params) do
      valid_account_params.merge(email: "")
    end

    let(:password_mismatch_params) do
      valid_account_params.merge("password-confirm": "different_password")
    end

    context "with valid parameters" do
      subject { post "/create-account", params: valid_account_params }

      it "creates an account" do
        expect { subject }.to change(Account, :count).by(1)
      end

      it "sends verification email" do
        expect {
          perform_enqueued_jobs do
            post "/create-account", params: valid_account_params
          end
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "with invalid email" do
      subject { post "/create-account", params: invalid_email_params }

      it "doesn't create account" do
        expect { subject }.not_to change(Account, :count)
      end

      it "shows validation error" do
        subject
        expect(response.body).to match(/email.*required|can't be blank/i)
      end
    end

    context "with mismatched passwords" do
      subject { post "/create-account", params: password_mismatch_params }

      it "doesn't create account" do
        expect { subject }.not_to change(Account, :count)
      end
    end
  end

  describe "POST /login" do
    let(:account) { create(:account, :verified) }

    def login_params(email: account.email, password: TestConstants::TEST_PASSWORD)
      {
        email: email,
        password: password
      }
    end

    context "with valid credentials" do
      subject { post "/login", params: login_params }

      it "logs in successfully" do
        subject
        expect(response).to redirect_to("/")
      end
    end

    context "with invalid password" do
      subject { post "/login", params: login_params(password: "wrong") }

      it "return 401 unauthorized" do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with non-existent email" do
      subject { post "/login", params: login_params(email: "fake@example.com") }

      it "return 401 unauthorized" do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /reset-password-request" do
    let(:verified_account) { create(:account, :verified) }

    def reset_password_params(email:)
      {email: email}
    end

    context "with verified account email" do
      it "sends reset email" do
        expect {
          perform_enqueued_jobs do
            post "/reset-password-request", params: reset_password_params(email: verified_account.email)
          end
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
