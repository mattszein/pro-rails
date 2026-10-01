# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Navbar", type: :request do
  describe "public navbar" do
    before { get "/" }

    it "renders sign in as a text link and register as a button" do
      html = Nokogiri::HTML(response.body)
      nav = html.at_css("nav")

      expect(nav.at_css("a[href='/login']")["class"]).to include("border-b-transparent")
      expect(nav.at_css("a[href='/create-account']")["class"]).to include("bg-highlight")
    end

    it "renders the brand logo" do
      expect(response.body).to include('aria-label="pro-rails"')
    end
  end

  describe "logged-in navbar" do
    let(:account) { create(:account, :verified) }

    before do
      login_user(account)
      get "/dashboard"
    end

    it "renders the logo as the drawer toggle" do
      html = Nokogiri::HTML(response.body)
      toggle = html.at_css("button[data-action='core--drawer-component#toggle']")

      expect(toggle.at_css("svg[aria-label='pro-rails']")).to be_present
    end
  end
end
