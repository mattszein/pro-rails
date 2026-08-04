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

  describe "GET #widget" do
    let(:widget_params) { {key: "tickets_personal"} }

    subject { get :widget, params: widget_params }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role and widget enabled" do
        before do
          login_user(user)
          ticket_permission = create(:permission, resource: :ticket, roles: [user.role])
          PermissionRole.where(permission_id: ticket_permission.id, role_id: user.role.id)
            .update_all(dashboard_widget_keys: ["tickets_personal"])
          @request.headers["Turbo-Frame"] = "dashboard_tickets_personal"
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, :ticket).with(Adminit::TicketPolicy).with_context(user: user)
        end

        it_behaves_like "respond to success"
      end

      context "with a role but widget not enabled" do
        before do
          login_user(user)
          create(:permission, resource: :ticket, roles: [user.role])
          @request.headers["Turbo-Frame"] = "dashboard_tickets_personal"
        end

        it "returns forbidden" do
          expect(subject).to have_http_status(:forbidden)
        end
      end

      context "when not a turbo frame request" do
        before do
          login_user(user)
          ticket_permission = create(:permission, resource: :ticket, roles: [user.role])
          PermissionRole.where(permission_id: ticket_permission.id, role_id: user.role.id)
            .update_all(dashboard_widget_keys: ["tickets_personal"])
        end

        it "redirects to root" do
          expect(subject).to redirect_to(root_url)
        end
      end

      context "with unknown widget" do
        let(:widget_params) { {key: "unknown"} }

        before do
          login_user(user)
          @request.headers["Turbo-Frame"] = "dashboard_unknown"
        end

        it "returns not found" do
          expect(subject).to have_http_status(:not_found)
        end
      end
    end
  end
end
