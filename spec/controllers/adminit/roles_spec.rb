# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::RolesController, type: :controller do
  include_context "user and permissions adminit"
  describe "GET #index" do
    subject { get :index, params: {} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user) # login user
          role_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, Role).with(Adminit::RolePolicy).with_context(user: user)
        end
        it_behaves_like "respond to success"
      end
    end
  end

  describe "GET #user_select" do
    subject { get :account_select, params: {id: user.role.id} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user) # login user
          role_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, Role).with(Adminit::RolePolicy).with_context(user: user)
        end
        it_behaves_like "respond to success"
      end
    end
  end

  describe "DELETE #remove_user" do
    include_context "user and permissions adminit"

    let(:new_user) { create(:account, :with_role, :verified) }
    let(:params) { {id: new_user.role.id, account_id: new_user.id} }

    subject { delete :remove_account, params: params }

    include_context "adminit_auth"
    context "when logged" do
      context "with a role" do
        before do
          login_user(user_superadmin) # login user
          role_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:remove_account?, new_user.role).with(Adminit::RolePolicy).with_context(user: user_superadmin)
        end

        it "remove user from role with valid id" do
          expect { subject }.to change { new_user.reload.role_id }.from(new_user.role_id).to(nil)
        end

        it "flashes a success message" do
          subject # call subject
          expect(flash[:notice]).not_to be_nil
        end
      end

      context "with a superadmin role" do
        before do
          role_permission
        end

        it "can't remove user if role is superadmin and it's the only one" do
          expect { subject }.not_to change { new_user.reload.role_id }
        end
      end

      context "with two superadmin roles" do
        let(:new_super_admin) { create(:account, role: user_superadmin.role) }
        let(:params) { {id: new_super_admin.role.id, account_id: new_super_admin.id} }

        before do
          role_permission
          login_user(user_superadmin) # login user
        end

        it "should remove account" do
          expect { subject }.to change { new_super_admin.reload.role }
        end
      end
    end
  end

  describe "POST #add_account" do
    include_context "user and permissions adminit"
    let(:new_user) { user_without_permissions }
    let(:params) { {id: user_superadmin.role.id, role: {email: new_user.email}} }

    subject { post :add_account, params: params }

    include_context "adminit_auth"

    context "when logged" do
      context "with proper permissions" do
        before do
          role_permission
          login_user(user_superadmin) # login superadmin user
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, user_superadmin.role).with(Adminit::RolePolicy).with_context(user: user_superadmin)
        end

        it "add user to role" do
          expect { subject }.to change { new_user.reload.role }
        end

        it "flashes a success message" do
          subject # call subject
          expect(flash[:notice]).not_to be_nil
        end
      end
    end
  end
end
