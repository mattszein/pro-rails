# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::DashboardsController, type: :controller do
  include_context "user and permissions adminit"

  describe "GET #index" do
    subject { get :index, params: {} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user)
          app_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:show?, :dashboard).with(Adminit::DashboardPolicy).with_context(user: user)
        end

        it_behaves_like "respond to success"
      end
    end
  end
end
