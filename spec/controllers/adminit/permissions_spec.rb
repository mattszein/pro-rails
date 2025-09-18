# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::PermissionsController, type: :controller do
  include_context "user and permissions adminit"

  describe "GET #index" do
    subject { get :index, params: {} }

    context "when logged" do
      context "with a permission role" do
        before do
          permissions_permission.reload
          login_user(user_superadmin) # login user
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, Permission).with(Adminit::PermissionPolicy).with_context(user: user_superadmin)
        end

        it_behaves_like "respond to success"
      end
    end
  end

  describe "PUT #update" do
    let(:role) { Role.create(name: "Role") }
    let(:params_update) { {id: permissions_permission.id, permission: {role_ids: (permissions_permission.role_ids << role.id).map(&:to_s)}} }

    subject { put :update, params: params_update }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user_superadmin) # login user
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:update?, permissions_permission).with(Adminit::PermissionPolicy).with_context(user: user_superadmin, role_ids: params_update[:permission][:role_ids])
        end

        it_behaves_like "respond with redirect"

        it "updates associated roles" do
          expect { subject }.to change { permissions_permission.reload.roles.count }.by(1)
        end

        it "adds the correct roles to permission" do
          subject
          permissions_permission.reload
          expect(permissions_permission.roles.pluck(:id)).to include(user_superadmin.role_id, role.id)
        end

        it "redirects to adminit_permissions_path" do
          expect(subject).to redirect_to adminit_permissions_path
        end

        it "flashes a success message" do
          subject # call subject
          expect(flash[:notice]).not_to be_nil
        end

        context "when role_ids contains invalid id" do
          before do
            params_update[:permission][:role_ids] << 0
          end

          it "flashes an alert message" do
            subject # call subject
            expect(flash[:alert]).not_to be_nil
          end

          it "doesn't update associated roles" do
            initial_count = permissions_permission.roles.count
            subject
            expect(permissions_permission.reload.roles.count).to eq(initial_count)
          end

          it "doesn't add invalid role associations" do
            subject
            permissions_permission.reload
            expect(permissions_permission.roles.exists?(id: 0)).to be_falsey
          end
        end

        context "when removing roles" do
          let(:params_update) { {id: permissions_permission.id, permission: {role_ids: [user_superadmin.role_id]}} }

          it "removes roles not in the new role_ids" do
            expect { subject }.to change { permissions_permission.reload.roles.count }.by(-1)
            expect(permissions_permission.roles).not_to include(user.role)
          end
        end
      end
    end
  end
end
