# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::TicketsController, type: :controller do
  include_context "user and permissions adminit"

  let(:creator_account) { create(:account, :verified) }
  let(:ticket_permission) { create(:permission, resource: Adminit::TicketPolicy.identifier, roles: [user.role, user_superadmin.role]) }

  describe "GET #index" do
    subject { get :index, params: {} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role" do
        before do
          login_user(user)
          ticket_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:manage?, Ticket).with(Adminit::TicketPolicy).with_context(user: user)
        end

        it_behaves_like "respond to success"
      end
    end
  end

  describe "POST #take" do
    let(:ticket) { create(:ticket, created: creator_account, assigned: nil, status: :open) }

    subject { post :take, params: {id: ticket.id} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role and unassigned ticket" do
        before do
          login_user(user)
          ticket_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:take?, ticket).with(Adminit::TicketPolicy).with_context(user: user)
        end

        it "assigns the ticket to the current admin" do
          expect { subject }.to change { ticket.reload.assigned_id }.from(nil).to(user.id)
        end

        it "changes ticket status to in_progress" do
          expect { subject }.to change { ticket.reload.status }.from("open").to("in_progress")
        end

        it "redirects to tickets index" do
          expect(subject).to redirect_to(adminit_tickets_path)
        end

        it "flashes a success message" do
          subject
          expect(flash[:notice]).to eq("Ticket was successfully assigned to you.")
        end
      end

      context "with an unassigned closed ticket" do
        let(:ticket) { create(:ticket, status: :closed, assigned: nil, created: creator_account) }

        before do
          login_user(user)
          ticket_permission
        end

        it "allows taking the ticket" do
          expect { subject }.to change { ticket.reload.assigned_id }.from(nil).to(user.id)
        end

        it "changes ticket status to in_progress" do
          expect { subject }.to change { ticket.reload.status }.from("closed").to("in_progress")
        end
      end

      context "with an already assigned ticket" do
        let(:other_admin) { create(:account, :with_role, :verified) }
        let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }

        before do
          login_user(user)
          ticket_permission
        end

        it "does not allow taking the ticket" do
          expect { subject }.not_to change { ticket.reload.assigned_id }
        end

        it_behaves_like "unauthorized"
      end
    end
  end

  describe "POST #leave" do
    let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: user) }

    subject { post :leave, params: {id: ticket.id} }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role and assigned to ticket" do
        before do
          login_user(user)
          ticket_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:leave?, ticket).with(Adminit::TicketPolicy).with_context(user: user)
        end

        it "unassigns the ticket from the admin" do
          expect { subject }.to change { ticket.reload.assigned_id }.from(user.id).to(nil)
        end

        it "changes ticket status to open" do
          expect { subject }.to change { ticket.reload.status }.from("in_progress").to("open")
        end

        it "redirects to tickets index" do
          expect(subject).to redirect_to(adminit_tickets_path)
        end

        it "flashes a success message" do
          subject
          expect(flash[:notice]).to eq("You have left the ticket.")
        end
      end

      context "when trying to leave a ticket not assigned to them" do
        let(:other_admin) { create(:account, :with_role, :verified) }
        let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }

        before do
          login_user(user)
          ticket_permission
        end

        it "does not allow leaving the ticket" do
          expect { subject }.not_to change { ticket.reload.assigned_id }
        end

        it_behaves_like "unauthorized"
      end
    end
  end

  describe "PATCH #update" do
    let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: user) }
    let(:params) { {id: ticket.id, ticket: {status: :closed}} }

    subject { patch :update, params: params }

    include_context "adminit_auth"

    context "when logged" do
      context "with a role and assigned to ticket" do
        before do
          login_user(user)
          ticket_permission
        end

        it "is authorized" do
          expect { subject }.to be_authorized_to(:update?, ticket).with(Adminit::TicketPolicy).with_context(user: user)
        end

        it "allows status update" do
          expect { subject }.to change { ticket.reload.status }.from("in_progress").to("closed")
        end

        it "redirects after update" do
          expect(subject).to have_http_status(:redirect)
        end

        it "flashes a success message" do
          subject
          expect(flash[:notice]).to eq("Ticket was successfully updated.")
        end
      end

      context "when not assigned to ticket" do
        let(:other_admin) { create(:account, :with_role, :verified) }
        let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }

        before do
          login_user(user)
          ticket_permission
        end

        it "does not allow updating the ticket" do
          expect { subject }.not_to change { ticket.reload.status }
        end

        it_behaves_like "unauthorized"
      end

      context "when superadmin updates any ticket" do
        let(:other_admin) { create(:account, :with_role, :verified) }
        let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }

        before do
          ticket_permission
          login_user(user_superadmin)
        end

        it "allows status update on any ticket" do
          expect { subject }.to change { ticket.reload.status }.from("in_progress").to("closed")
        end
      end
    end
  end
end
