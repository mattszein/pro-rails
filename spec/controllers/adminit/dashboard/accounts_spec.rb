# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::Dashboard::AccountsController, type: :controller do
  include_context "user and permissions adminit"

  describe "GET #search" do
    subject { get :search, params: {q: query}, format: :json }

    let(:query) { "lookupguy" }

    include_context "adminit_auth"

    context "when logged with account permission" do
      before do
        account_permission
        login_user(user)
      end

      # Adminit::AccountPolicy has no show? rule — ActionPolicy falls back to
      # the default_rule (manage?).
      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Account).with(Adminit::AccountPolicy).with_context(user: user)
      end

      it "returns minimal value/text pairs for TomSelect" do
        match = create(:account, :verified, email: "lookupguy@example.com")

        subject
        results = JSON.parse(response.body)

        expect(results).to eq([{"value" => match.id.to_s, "text" => match.email}])
      end

      context "with a query shorter than 2 characters" do
        let(:query) { "l" }

        it "returns an empty array" do
          subject
          expect(JSON.parse(response.body)).to eq([])
        end
      end
    end
  end

  describe "GET #summary" do
    let(:target_account) { create(:account, :verified) }

    subject { get :summary, params: {id: target_account.id} }

    include_context "adminit_auth"

    context "when logged with account permission" do
      before do
        account_permission
        login_user(user)
      end

      context "with a turbo frame request" do
        before { @request.headers["Turbo-Frame"] = "account_summary" }

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, target_account).with(Adminit::AccountPolicy).with_context(user: user)
        end

        it_behaves_like "respond to success"
      end

      context "when not a turbo frame request" do
        it "redirects to root" do
          expect(subject).to redirect_to(root_url)
        end
      end
    end
  end
end
