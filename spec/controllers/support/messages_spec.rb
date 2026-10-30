# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

RSpec.describe Support::MessagesController, type: :controller do
  let(:creator_account) { create(:account, :verified) }
  let(:assignee_account) { create(:account, :with_role, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:ticket) { create(:ticket, created_id: creator_account.id, assigned_id: assignee_account.id, status: :in_progress) }
  let(:conversation) { ticket.conversation }

  describe "POST #create" do
    let(:valid_params) { {ticket_id: ticket.id, support_message: {content: "Hello world"}} }
    let(:invalid_params) { {ticket_id: ticket.id, support_message: {content: ""}} }

    subject { post :create, params: params, as: :turbo_stream }

    context "when not logged in" do
      let(:params) { valid_params }

      it "redirects to login" do
        expect(subject).to redirect_to(rodauth.login_path)
      end

      it "sets a flash alert" do
        subject
        expect(flash[:alert]).to eq("Please login to continue")
      end

      it "does not create a message" do
        expect { subject }.not_to change(Support::Message, :count)
      end
    end

    context "when logged in as ticket creator" do
      before { login_user(creator_account) }

      context "with valid parameters" do
        let(:params) { valid_params }

        it_behaves_like "respond to success"

        it "is authorized" do
          expect { subject }.to be_authorized_to(:create?, an_instance_of(Support::Message)).with(Support::MessagePolicy).with_context(user: creator_account)
        end

        it "creates a new message" do
          expect { subject }.to change(Support::Message, :count).by(1)
        end

        it "assigns the message to the current account" do
          subject
          expect(Support::Message.last.account_id).to eq(creator_account.id)
        end

        it "assigns the message to the correct conversation" do
          subject
          expect(Support::Message.last.conversation_id).to eq(conversation.id)
        end

        it "sets the correct message content" do
          subject
          expect(Support::Message.last.content).to eq("Hello world")
        end

        it "renders turbo_stream response" do
          subject
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      context "with invalid parameters" do
        let(:params) { invalid_params }

        it "does not create a new message" do
          expect { subject }.not_to change(Support::Message, :count)
        end

        it "responds with success status even with validation errors" do
          subject
          expect(response).to have_http_status(200)
        end
      end
    end

    context "when logged in as ticket assignee (admin)" do
      before { login_user(assignee_account) }

      context "with valid parameters" do
        let(:params) { valid_params }

        it_behaves_like "respond to success"

        it "is authorized" do
          expect { subject }.to be_authorized_to(:create?, an_instance_of(Support::Message)).with(Support::MessagePolicy).with_context(user: assignee_account)
        end

        it "creates a new message" do
          expect { subject }.to change(Support::Message, :count).by(1)
        end

        it "assigns the message to the assignee account" do
          subject
          expect(Support::Message.last.account_id).to eq(assignee_account.id)
        end

        it "assigns the message to the correct conversation" do
          subject
          expect(Support::Message.last.conversation_id).to eq(conversation.id)
        end
      end

      context "with invalid parameters" do
        let(:params) { invalid_params }

        it "does not create a new message" do
          expect { subject }.not_to change(Support::Message, :count)
        end
      end
    end

    context "when logged in as unauthorized user" do
      before { login_user(other_account) }

      let(:params) { valid_params }

      it "responds with success (turbo stream)" do
        expect(subject).to have_http_status(200)
      end

      it "sets unauthorized flash alert" do
        subject
        expect(flash.now[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
      end

      it "does not create a message" do
        expect { subject }.not_to change(Support::Message, :count)
      end
    end

    context "when an admin writes on an unassigned or someone else's ticket" do
      let(:params) { valid_params }
      let(:other_admin) { create(:account, :with_role, :verified) }

      before { login_user(assignee_account) }

      it "rejects an unassigned ticket" do
        ticket.update_columns(assigned_id: nil, status: Support::Ticket.statuses[:open])
        expect { subject }.not_to change(Support::Message, :count)
        expect(flash.now[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
      end

      it "rejects a ticket assigned to another admin" do
        ticket.update_columns(assigned_id: other_admin.id)
        expect { subject }.not_to change(Support::Message, :count)
        expect(flash.now[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
      end
    end

    context "when ticket has no assignee (open status)" do
      let(:ticket) { create(:ticket, created_id: creator_account.id, assigned_id: nil, status: :open) }

      before { login_user(creator_account) }

      context "creator cannot send messages on open tickets" do
        let(:params) { valid_params }

        it "does not create a message" do
          expect { subject }.not_to change(Support::Message, :count)
        end
      end
    end

    context "when assignee is different from creator" do
      let(:different_creator) { create(:account, :verified) }
      let(:different_assignee) { create(:account, :with_role, :verified) }
      let(:ticket) { create(:ticket, created_id: different_creator.id, assigned_id: different_assignee.id, status: :in_progress) }

      before { login_user(different_assignee) }

      context "assignee can send messages on other users' tickets" do
        let(:params) { valid_params }

        it "is authorized" do
          expect { subject }.to be_authorized_to(:create?, an_instance_of(Support::Message)).with(Support::MessagePolicy).with_context(user: different_assignee)
        end

        it "creates a new message" do
          expect { subject }.to change(Support::Message, :count).by(1)
        end

        it "assigns the message to the assignee" do
          subject
          expect(Support::Message.last.account_id).to eq(different_assignee.id)
        end
      end
    end

    context "when ticket does not exist" do
      before { login_user(creator_account) }

      let(:params) { {ticket_id: 999999, support_message: {content: "Hello world"}} }

      it "responds with not found status" do
        expect(subject).to have_http_status(:not_found)
      end

      it "sets ticket not found flash alert" do
        subject
        expect(flash.now[:alert]).to eq(I18n.t("errors.record_not_found"))
      end

      it "does not create a message" do
        expect { subject }.not_to change(Support::Message, :count)
      end
    end
  end

  describe "AI engaged tickets" do
    subject { post :create, params: {ticket_id: ticket.id, support_message: {content: "Hello"}}, as: :turbo_stream }

    let(:ticket) { create(:ticket, created_id: creator_account.id, status: :open, ai_state: state) }
    let(:state) { :awaiting_user }

    context "when the requester writes on an open ticket the AI is handling" do
      before { login_user(creator_account) }

      it "creates the message (the ticket is messageable)" do
        expect { subject }.to change(Support::Message, :count).by(1)
        expect(Support::Message.last).to be_human
      end

      it "resumes the AI and enqueues the job for the message" do
        expect { subject }.to have_enqueued_job(Support::AiProcessJob).with(ticket.id, "user_message", a_kind_of(Integer))
        expect(ticket.reload).to be_ai_analyzing
      end

      context "when the AI has handed off" do
        let(:state) { :handoff_requested }

        it "still accepts the message with no AI work" do
          expect { subject }.to change(Support::Message, :count).by(1)
          expect { subject }.not_to have_enqueued_job(Support::AiProcessJob)
        end
      end

      context "when the assistant is analyzing" do
        let(:state) { :analyzing }

        it "rejects a direct POST: no message, no job" do
          expect { subject }.not_to change(Support::Message, :count)
          expect { subject }.not_to have_enqueued_job(Support::AiProcessJob)
          expect(ticket.reload).to be_ai_analyzing
        end
      end

      context "when the AI is off" do
        let(:state) { :off }

        it "keeps the old rule: no messages on an open, unassigned ticket" do
          expect { subject }.not_to change(Support::Message, :count)
        end
      end
    end

    context "when an admin who has not taken the ticket writes" do
      before { login_user(assignee_account) }

      it "is rejected and leaves the AI untouched" do
        expect { subject }.not_to change(Support::Message, :count)
        expect(ticket.reload.ai_state).to eq(state.to_s)
      end
    end

    context "when the admin takes it first" do
      before do
        login_user(assignee_account)
        ticket.assign!(to: assignee_account, by: assignee_account)
      end

      it "can write, and taking already stepped the AI back" do
        expect { subject }.to change(Support::Message, :count).by(1)
        expect(ticket.reload).to be_ai_stepped_back
        expect(ticket.notes.system.pluck(:body)).to include("AI stepped back.")
      end
    end
  end
end
