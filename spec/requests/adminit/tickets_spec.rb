require "rails_helper"

RSpec.describe "Adminit::Tickets", type: :request do
  let(:admin_role) { create(:role, name: "admin") }
  let(:permission) { create(:permission, resource: Adminit::TicketPolicy.identifier, roles: [admin_role]) }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:creator_account) { create(:account, :verified) }
  let(:ticket) { create(:ticket, created: creator_account) }

  before do
    permission # Ensure permission exists
  end

  describe "POST /adminit/tickets/:id/take" do
    context "when admin is logged in" do
      before { login_user(admin_account) }

      context "with an open ticket" do
        it "assigns the ticket to the current admin" do
          expect {
            post take_adminit_ticket_path(ticket)
          }.to change { ticket.reload.assigned_id }.from(nil).to(admin_account.id)
        end

        it "changes ticket status to in_progress" do
          expect {
            post take_adminit_ticket_path(ticket)
          }.to change { ticket.reload.status }.from("open").to("in_progress")
        end

        it "redirects to tickets index" do
          post take_adminit_ticket_path(ticket)
          expect(response).to redirect_to(adminit_tickets_path)
        end

        it "shows success notice" do
          post take_adminit_ticket_path(ticket)
          follow_redirect!
          expect(response.body).to include("Ticket was successfully assigned to you")
        end
      end

      context "with a non-open ticket" do
        let(:ticket) { create(:ticket, :in_progress, created: creator_account) }

        it "does not assign the ticket" do
          expect {
            post take_adminit_ticket_path(ticket)
          }.not_to change { ticket.reload.assigned_id }
        end

        it "redirects with authorization error" do
          post take_adminit_ticket_path(ticket)
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    context "when admin is not logged in" do
      it "redirects to login" do
        post take_adminit_ticket_path(ticket)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when user without admin role is logged in" do
      let(:regular_user) { create(:account, :verified) }

      before { login_user(regular_user) }

      it "redirects to root path" do
        post take_adminit_ticket_path(ticket)
        expect(response).to redirect_to("/")
      end
    end
  end

  describe "PATCH /adminit/tickets/:id" do
    context "when admin has taken the ticket" do
      let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: admin_account) }

      before { login_user(admin_account) }

      it "allows status update" do
        expect {
          patch adminit_ticket_path(ticket), params: {ticket: {status: :closed}}
        }.to change { ticket.reload.status }.from("in_progress").to("closed")
      end

      it "shows success notice" do
        patch adminit_ticket_path(ticket), params: {ticket: {status: :closed}}
        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response.body).to include("Ticket was successfully updated")
      end
    end

    context "when admin has not taken the ticket" do
      let(:other_admin) { create(:account, :verified, role: admin_role) }
      let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }

      before { login_user(admin_account) }

      it "redirects with authorization error for non-assigned admin" do
        patch adminit_ticket_path(ticket), params: {ticket: {status: :closed}}
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when superadmin updates any ticket" do
      let(:superadmin_role) { create(:role, :superadmin) }
      let(:superadmin_account) { create(:account, :verified, role: superadmin_role) }
      let(:other_admin) { create(:account, :verified, role: admin_role) }
      let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }

      before do
        # Add superadmin role to existing permission
        permission.roles << superadmin_role unless permission.roles.include?(superadmin_role)
        login_user(superadmin_account)
      end

      it "allows status update on any ticket" do
        expect {
          patch adminit_ticket_path(ticket), params: {ticket: {status: :closed}}
        }.to change { ticket.reload.status }.from("in_progress").to("closed")
      end
    end
  end

  describe "GET /adminit/tickets" do
    context "when admin is logged in" do
      before { login_user(admin_account) }

      it "shows all tickets" do
        ticket # Create the ticket
        get adminit_tickets_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(ticket.title)
      end
    end

    context "when user without admin role is logged in" do
      let(:regular_user) { create(:account, :verified) }

      before { login_user(regular_user) }

      it "redirects to root path" do
        get adminit_tickets_path
        expect(response).to redirect_to("/")
      end
    end
  end
end
