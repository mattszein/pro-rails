# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::TicketsController, type: :controller do
  include_context "user and permissions adminit"

  let(:creator_account) { create(:account, :verified) }
  let(:ticket_permission) { create(:permission, resource: :ticket, roles: [user.role, user_superadmin.role]) }

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
          expect { subject }.to be_authorized_to(:manage?, Support::Ticket).with(Adminit::TicketPolicy).with_context(user: user)
        end

        it_behaves_like "respond to success"

        it "paginates results" do
          subject
          expect(controller.instance_variable_get(:@pagy)).to be_a(Pagy)
        end

        context "with sort params" do
          let(:ticket_a) { create(:ticket, title: "Alpha", created: creator_account) }
          let(:ticket_b) { create(:ticket, title: "Beta", created: creator_account) }

          before do
            ticket_a
            ticket_b
          end

          it "sorts by title asc" do
            get :index, params: {sort: "title", direction: "asc"}
            tickets = controller.instance_variable_get(:@tickets)
            expect(tickets.first.title).to eq("Alpha")
          end

          it "sorts by title desc" do
            get :index, params: {sort: "title", direction: "desc"}
            tickets = controller.instance_variable_get(:@tickets)
            expect(tickets.first.title).to eq("Beta")
          end

          it "ignores invalid sort params" do
            expect { get :index, params: {sort: "malicious_column", direction: "asc"} }.not_to raise_error
          end
        end

        context "with filter params" do
          let!(:open_ticket) { create(:ticket, status: :open, created: creator_account) }
          let!(:closed_ticket) { create(:ticket, status: :closed, created: creator_account) }

          it "filters by status" do
            get :index, params: {filter: {status: "open"}}
            tickets = controller.instance_variable_get(:@tickets)
            expect(tickets).to all(have_attributes(status: "open"))
          end

          it "filters by assignee" do
            assignee = create(:account, :with_role, :verified)
            assigned_ticket = create(:ticket, created: creator_account, assigned: assignee)

            get :index, params: {filter: {assignee: assignee.id}}
            tickets = controller.instance_variable_get(:@tickets)
            expect(tickets).to contain_exactly(assigned_ticket)
          end

          it "ignores filter params that aren't declared on any column" do
            get :index, params: {filter: {priority: "5"}}
            tickets = controller.instance_variable_get(:@tickets)
            expect(tickets).to contain_exactly(open_ticket, closed_ticket)
          end
        end

        context "with created_at sort" do
          let!(:old_ticket) { create(:ticket, created: creator_account, created_at: 2.days.ago) }
          let!(:new_ticket) { create(:ticket, created: creator_account, created_at: 1.hour.ago) }

          it "sorts by created_at asc" do
            get :index, params: {sort: "created_at", direction: "asc"}
            tickets = controller.instance_variable_get(:@tickets)
            expect(tickets.first).to eq(old_ticket)
          end

          it "sorts by created_at desc" do
            get :index, params: {sort: "created_at", direction: "desc"}
            tickets = controller.instance_variable_get(:@tickets)
            expect(tickets.first).to eq(new_ticket)
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
    subject { get :show, params: {id: ticket.id} }

    let(:ticket) { create(:ticket, created: creator_account) }

    before do
      login_user(user)
      ticket_permission
      ticket.notes.create!(body: "internal note", account: user)
      create(:message, conversation: ticket.conversation, account: creator_account)
    end

    it_behaves_like "respond to success"

    it "preloads notes and messages with their accounts for the view" do
      subject
      loaded = controller.instance_variable_get(:@ticket)

      expect(loaded.association(:notes)).to be_loaded
      expect(loaded.notes.first.association(:account)).to be_loaded
      expect(loaded.conversation.association(:messages)).to be_loaded
      expect(loaded.conversation.messages.first.association(:account)).to be_loaded
    end
  end

  describe "GET #index AI state" do
    render_views

    before do
      login_user(user)
      ticket_permission
    end

    let!(:needs_human) { create(:ticket, :ai_handoff_requested, title: "Needs a person", created: creator_account) }
    let!(:plain) { create(:ticket, title: "Plain one", created: creator_account) }

    it "renders the AI state column with the Needs human badge" do
      get :index
      expect(response.body).to include("Needs human")
    end

    it "filters by ai_state" do
      get :index, params: {filter: {ai_state: "handoff_requested"}}
      expect(controller.instance_variable_get(:@tickets)).to contain_exactly(needs_human)
    end

    it "sorts by ai_state" do
      get :index, params: {sort: "ai_state", direction: "desc"}
      expect(controller.instance_variable_get(:@tickets).first).to eq(needs_human)
    end

    it "ignores an unknown ai_state filter value without raising" do
      expect { get :index, params: {filter: {ai_state: "bogus"}} }.not_to raise_error
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #show with the assistant" do
    render_views

    let(:ticket) { create(:ticket, :ai_handoff_requested, created: creator_account) }
    let(:playbook) { create(:ai_playbook, name: "Billing flow") }

    before do
      login_user(user)
      ticket_permission
      ticket.update!(ai_playbook: playbook)
      create(:ai_run, ticket: ticket, step: :respond, model: "demo-model")
      ticket.notes.create!(kind: :ai, account: nil, body: "AI summary body")
      ticket.notes.create!(kind: :system, account: nil, body: "system body")
    end

    it "shows the AI badge, playbook, AI activity panel, AI note styling and the takeover label" do
      get :show, params: {id: ticket.id}
      body = response.body

      expect(body).to include("Needs human")
      expect(body).to include("Billing flow")
      expect(body).to include(I18n.t("adminit.tickets.ai_activity"))
      expect(body).to include("demo-model")
      expect(body).to include("/ai_runs/")
      expect(body).to include("border-violet-400")
      expect(body).to include("system body")
      expect(body).to include(I18n.t("adminit.tickets.take_over_from_ai"))
    end

    it "keeps the plain Take label when the assistant is not engaged and hides the AI panel" do
      plain = create(:ticket, created: creator_account)
      get :show, params: {id: plain.id}

      expect(response.body).to include(">#{I18n.t("shared.buttons.take")}<")
      expect(response.body).not_to include(I18n.t("adminit.tickets.ai_activity"))
    end

    it "preloads the playbook and runs" do
      get :show, params: {id: ticket.id}
      loaded = controller.instance_variable_get(:@ticket)

      expect(loaded.association(:ai_playbook)).to be_loaded
      expect(loaded.association(:ai_runs)).to be_loaded
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

        it "redirects to the ticket" do
          expect(subject).to redirect_to(adminit_ticket_path(ticket))
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
    let(:params) { {id: ticket.id, support_ticket: {status: :closed}} }

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
