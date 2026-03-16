# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locale routing", type: :request do
  let(:account) { create(:account, :verified) }

  before { login_user(account) }

  describe "Spanish locale prefix" do
    it "GET /es/dashboard responds with success" do
      get "/es/dashboard"
      expect(response).to have_http_status(:success)
    end

    it "renders Spanish content on /es/dashboard" do
      get "/es/dashboard"
      expect(response.body).to include("Has iniciado sesión como")
    end

    it "renders English content on /dashboard (no prefix)" do
      get "/dashboard"
      expect(response.body).to include("You are signed in as")
    end
  end

  describe "locale persistence in redirects" do
    it "preserves Spanish locale in redirect after creating a support ticket" do
      post "/es/support/tickets", params: {
        support_ticket: {
          title: "Test ticket",
          description: "Test description",
          category: "account_access"
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/es/")
    end

    it "omits locale prefix for English redirects" do
      post "/support/tickets", params: {
        support_ticket: {
          title: "Test ticket",
          description: "Test description",
          category: "account_access"
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(response.location).not_to match(%r{/(en|es)/})
    end
  end

  describe "URL helper locale generation" do
    it "generates unprefixed URLs for English locale" do
      get "/dashboard"
      expect(response.body).not_to match(%r{/(en|es)/settings/appearance})
    end

    it "generates /es/ prefixed URLs for Spanish locale" do
      get "/es/dashboard"
      expect(response.body).to include("/es/")
    end
  end

  describe "invalid locale" do
    it "does not match unknown locale prefixes" do
      get "/fr/dashboard"
      # /fr/dashboard does not match the locale scope constraint, so Rails treats it as a different route
      expect(response).not_to have_http_status(:success)
    end
  end
end
