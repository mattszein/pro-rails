# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::AccountsController, type: :controller do
  include_context "user and permissions adminit"

  describe "GET #index" do
    subject { get :index }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user)
          account_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, Account).with(Adminit::AccountPolicy).with_context(user: user)
        end

        it_behaves_like "respond to success"

        it "paginates results" do
          subject
          expect(controller.instance_variable_get(:@pagy)).to be_a(Pagy)
        end

        context "with sort params" do
          let!(:account_a) { create(:account, :verified, email: "aaa@example.com") }
          let!(:account_b) { create(:account, :verified, email: "zzz@example.com") }

          it "sorts by email asc" do
            get :index, params: {sort: "email", direction: "asc"}
            accounts = controller.instance_variable_get(:@accounts)
            expect(accounts.map(&:email)).to eq(accounts.map(&:email).sort)
          end

          it "sorts by email desc" do
            get :index, params: {sort: "email", direction: "desc"}
            accounts = controller.instance_variable_get(:@accounts)
            expect(accounts.map(&:email)).to eq(accounts.map(&:email).sort.reverse)
          end

          it "ignores invalid sort params" do
            expect { get :index, params: {sort: "malicious_column", direction: "asc"} }.not_to raise_error
          end
        end

        context "with filter params" do
          let!(:verified_account) { create(:account, :verified) }
          let!(:unverified_account) { create(:account, :unverified) }

          it "filters by status" do
            get :index, params: {filter: {status: "verified"}}
            accounts = controller.instance_variable_get(:@accounts)
            expect(accounts).to all(have_attributes(status: "verified"))
          end

          it "filters by search" do
            get :index, params: {filter: {search: verified_account.email}}
            accounts = controller.instance_variable_get(:@accounts)
            expect(accounts.map(&:email)).to include(verified_account.email)
          end

          it "ignores filter params that aren't declared on any column" do
            get :index, params: {filter: {unverified_at: "anything"}}
            accounts = controller.instance_variable_get(:@accounts)
            expect(accounts.map(&:email)).to include(verified_account.email, unverified_account.email)
          end
        end

        context "with created_at sort" do
          # `user` (logged-in admin) also exists in the unfiltered relation, so
          # assert relative order between the two fixtures rather than assuming
          # either lands first overall.
          let!(:old_account) { create(:account, :verified, created_at: 3.days.ago) }
          let!(:new_account) { create(:account, :verified, created_at: 2.days.ago) }

          it "sorts by created_at asc" do
            get :index, params: {sort: "created_at", direction: "asc"}
            accounts = controller.instance_variable_get(:@accounts).to_a
            expect(accounts.index(old_account)).to be < accounts.index(new_account)
          end

          it "sorts by created_at desc" do
            get :index, params: {sort: "created_at", direction: "desc"}
            accounts = controller.instance_variable_get(:@accounts).to_a
            expect(accounts.index(new_account)).to be < accounts.index(old_account)
          end
        end

        context "with out-of-range page" do
          it "returns last page instead of error" do
            expect { get :index, params: {page: 99999} }.not_to raise_error
            expect(response).to have_http_status(200)
          end
        end
      end
    end
  end

  describe "GET #show" do
    let(:account) { create(:account, :verified) }

    subject { get :show, params: {id: account.id} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user)
          account_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, account).with(Adminit::AccountPolicy).with_context(user: user)
        end

        it_behaves_like "respond to success"
      end
    end
  end

  describe "GET #search" do
    subject { get :search, params: {q: "user_"} }

    include_context "adminit_auth"

    shared_examples "a permitted searcher" do
      it "is authorized" do
        expect { subject }.to be_authorized_to(:search?, Account).with(Adminit::AccountPolicy).with_context(user: user)
      end

      it "returns matching accounts as {value, text}" do
        matching = create(:account, email: "user_match@example.com")

        subject

        expect(response.parsed_body).to include("value" => matching.id.to_s, "text" => matching.email)
      end

      it "short-circuits a too-short query to an empty list" do
        get :search, params: {q: "a"}
        expect(response.parsed_body).to eq([])
      end
    end

    context "with the account permission" do
      before do
        login_user(user)
        account_permission
      end

      it_behaves_like "a permitted searcher"
    end

    context "with the role permission" do
      before do
        login_user(user)
        role_permission
      end

      it_behaves_like "a permitted searcher"
    end

    context "with the feature_flag permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it_behaves_like "a permitted searcher"
    end

    context "with a not_in_role param" do
      before do
        login_user(user)
        account_permission
      end

      it "excludes accounts already holding that role" do
        role = create(:role)
        member = create(:account, email: "user_member@example.com", role: role)
        other = create(:account, email: "user_other@example.com")

        get :search, params: {q: "user_", not_in_role: role.id}

        values = response.parsed_body.pluck("value")
        expect(values).to include(other.id.to_s)
        expect(values).not_to include(member.id.to_s)
      end
    end

    context "with an exclude_closed param" do
      before do
        login_user(user)
        account_permission
      end

      it "excludes closed accounts" do
        open = create(:account, email: "user_open@example.com")
        closed = create(:account, :closed, email: "user_closed@example.com")

        get :search, params: {q: "user_", exclude_closed: true}

        values = response.parsed_body.pluck("value")
        expect(values).to include(open.id.to_s)
        expect(values).not_to include(closed.id.to_s)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:account) { create(:account, :verified) }

    subject { delete :destroy, params: {id: account.id} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user)
          account_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, account).with(Adminit::AccountPolicy).with_context(user: user)
        end

        it "destroys the account" do
          account
          expect { subject }.to change(Account, :count).by(-1)
        end

        it "redirects to accounts index" do
          subject
          expect(response).to redirect_to(adminit_accounts_url)
        end
      end
    end
  end
end
