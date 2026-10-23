require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

RSpec.describe Support::TicketsController, type: :controller do
  let(:creator_account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:ticket) { create(:ticket, created: creator_account) }

  describe "GET #index" do
    subject { get :index }

    context "when not logged in" do
      it "redirects to login" do
        expect(subject).to redirect_to(rodauth.login_path)
      end

      it "sets a flash alert" do
        subject
        expect(flash[:alert]).to eq("Please login to continue")
      end
    end

    context "when logged in" do
      before { login_user(creator_account) }

      it_behaves_like "respond to success"

      it "is authorized" do
        expect { subject }.to be_authorized_to(:index?, :ticket).with(Support::TicketPolicy).with_context(user: creator_account)
      end

      it "returns only the current user's tickets" do
        ticket # create creator's ticket
        create(:ticket, created: other_account)

        subject

        expect(controller.instance_variable_get(:@tickets)).to contain_exactly(ticket)
      end

      it "paginates results" do
        subject
        expect(controller.instance_variable_get(:@pagy)).to be_a(Pagy)
      end

      context "with a filter applied" do
        it "narrows within the owner's tickets but never returns another account's ticket" do
          own_open = create(:ticket, status: :open, created: creator_account)
          create(:ticket, status: :closed, created: creator_account)
          create(:ticket, status: :open, created: other_account)

          get :index, params: {filter: {status: "open"}}

          expect(controller.instance_variable_get(:@tickets)).to contain_exactly(own_open)
        end
      end

      context "with created_at sort" do
        it "sorts by created_at asc" do
          old_ticket = create(:ticket, created: creator_account, created_at: 2.days.ago)
          create(:ticket, created: creator_account, created_at: 1.hour.ago)

          get :index, params: {sort: "created_at", direction: "asc"}

          expect(controller.instance_variable_get(:@tickets).first).to eq(old_ticket)
        end
      end
    end
  end

  describe "GET #show with the assistant" do
    render_views

    before { login_user(creator_account) }

    def show(ticket)
      get :show, params: {id: ticket.id}
      response.body
    end

    it "shows the helping banner, typing indicator and the talk-to-person button while analyzing" do
      body = show(create(:ticket, :ai_analyzing, created: creator_account))

      expect(body).to include(I18n.t("support.ticket_status_banner.ai_analyzing"))
      expect(body).to include("typing_support_conversation_")
      expect(body).to include(I18n.t("support.ai_status.talk_to_person"))
      expect(body).to include("is=\"#{creator_account.id}\"")
    end

    it "shows the helping banner without typing while awaiting the user" do
      body = show(create(:ticket, :ai_awaiting_user, created: creator_account))

      expect(body).to include(I18n.t("support.ticket_status_banner.ai_awaiting_user"))
      expect(body).not_to include("typing_support_conversation_")
      expect(body).to include(I18n.t("support.ai_status.talk_to_person"))
    end

    it "shows the waiting banner, no talk-to-person button and a live composer on handoff" do
      body = show(create(:ticket, :ai_handoff_requested, created: creator_account))

      expect(body).to include(I18n.t("support.ticket_status_banner.ai_handoff_requested"))
      expect(body).not_to include(I18n.t("support.ai_status.talk_to_person"))
      expect(body).to include(I18n.t("support.messages.placeholder"))
    end

    it "shows the resolved banner and the reopen form for an AI-resolved ticket" do
      body = show(create(:ticket, :ai_resolved, created: creator_account))

      expect(body).to include(I18n.t("support.ticket_status_banner.ai_resolved"))
      expect(body).to include(I18n.t("support.reopen_form.request_reopen"))
    end

    it "keeps the normal in-progress experience once a human stepped in" do
      body = show(create(:ticket, :in_progress, ai_state: :stepped_back, created: creator_account))

      expect(body).not_to include("ai-status-banner")
      expect(body).not_to include(I18n.t("support.ai_status.talk_to_person"))
      expect(body).to include(I18n.t("support.messages.placeholder"))
    end

    it "renders the solved buttons only on the latest AI message that proposes a resolution" do
      ticket = create(:ticket, :ai_awaiting_user, created: creator_account)
      create(:message, :ai, conversation: ticket.conversation, content: "first",
        metadata: {"article_ids" => [], "resolution_proposed" => true}, created_at: 2.minutes.ago)
      create(:message, :ai, conversation: ticket.conversation, content: "second",
        metadata: {"article_ids" => [], "resolution_proposed" => true}, created_at: 1.minute.ago)

      body = show(ticket)

      expect(body.scan("data-resolution-actions").size).to eq(1)
      expect(body).to include(I18n.t("support.message.solved"))
    end

    it "lists article cards from an AI message" do
      article = create(:article, :published, title: "Fix the thing")
      ticket = create(:ticket, :ai_awaiting_user, created: creator_account)
      create(:message, :ai, conversation: ticket.conversation, metadata: {"article_ids" => [article.id], "resolution_proposed" => false})

      expect(show(ticket)).to include("Fix the thing")
    end
  end

  describe "GET #show" do
    subject { get :show, params: {id: ticket.id} }

    context "when not logged in" do
      it "redirects to login" do
        expect(subject).to redirect_to(rodauth.login_path)
      end

      it "sets a flash alert" do
        subject
        expect(flash[:alert]).to eq("Please login to continue")
      end
    end

    context "when logged in as ticket creator" do
      before { login_user(creator_account) }

      it_behaves_like "respond to success"

      it "is authorized" do
        expect { subject }.to be_authorized_to(:show?, ticket).with(Support::TicketPolicy).with_context(user: creator_account)
      end
    end

    context "when logged in as other user" do
      before { login_user(other_account) }

      it "denies access" do
        subject
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
      end
    end

    context "when ticket does not exist" do
      before { login_user(creator_account) }

      it "handles not found" do
        get :show, params: {id: 999999}
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET #new" do
    context "when not logged in" do
      it "redirects to login" do
        expect(get(:new)).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in" do
      before { login_user(creator_account) }

      it "redirects non-turbo-frame requests to root" do
        expect(get(:new)).to redirect_to(root_path)
      end

      context "with turbo frame request" do
        before { @request.headers["Turbo-Frame"] = "modal" }

        subject { get :new }

        it_behaves_like "respond to success"

        it "is authorized" do
          expect { subject }.to be_authorized_to(:new?, :ticket).with(Support::TicketPolicy).with_context(user: creator_account)
        end

        context "when rendering views" do
          render_views

          it "renders the article suggestions frame and controller" do
            subject
            expect(response.body).to include('data-controller="article-suggestions"', 'id="help_suggestions"', suggestions_help_articles_path)
          end
        end
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) { {support_ticket: {title: "Test ticket", description: "A description", category: "account_access"}} }
    let(:invalid_params) { {support_ticket: {title: "", description: "", category: "account_access"}} }

    context "when not logged in" do
      subject { post :create, params: valid_params }

      it "redirects to login" do
        expect(subject).to redirect_to(rodauth.login_path)
      end

      it "does not create a ticket" do
        expect { subject }.not_to change(Support::Ticket, :count)
      end
    end

    context "when logged in" do
      before { login_user(creator_account) }

      context "with valid parameters" do
        subject { post :create, params: valid_params }

        it "is authorized" do
          expect { subject }.to be_authorized_to(:create?, a_kind_of(Support::Ticket)).with(Support::TicketPolicy).with_context(user: creator_account)
        end

        it "creates a new ticket" do
          expect { subject }.to change(Support::Ticket, :count).by(1)
        end

        it "assigns the ticket to the current account" do
          subject
          expect(Support::Ticket.unscoped.last.created_id).to eq(creator_account.id)
        end

        it "creates a conversation for the ticket" do
          expect { subject }.to change(Support::Conversation, :count).by(1)
        end

        it "sets a flash notice" do
          subject
          expect(flash[:notice]).to eq("Ticket was successfully created")
        end

        it "redirects to the new ticket" do
          subject
          expect(response).to have_http_status(:redirect)
        end
      end

      context "with invalid parameters" do
        subject { post :create, params: invalid_params }

        it "does not create a ticket" do
          expect { subject }.not_to change(Support::Ticket, :count)
        end

        it "responds with unprocessable entity" do
          subject
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "POST #attach_files" do
    let(:file) { fixture_file_upload("test_file.txt", "image/png") }

    subject { post :attach_files, params: {id: ticket.id, support_ticket: {attachments: [file]}} }

    context "when not logged in" do
      it "redirects to login" do
        expect(subject).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in as ticket creator" do
      before { login_user(creator_account) }

      it "is authorized" do
        expect { subject }.to be_authorized_to(:attach_files?, ticket).with(Support::TicketPolicy).with_context(user: creator_account)
      end

      it "attaches the file" do
        expect { subject }.to change { ticket.reload.attachments.count }.by(1)
      end

      it "redirects to the ticket" do
        expect(subject).to redirect_to(support_ticket_path(ticket))
      end

      it "sets a flash notice" do
        subject
        expect(flash[:notice]).to eq("Files were successfully attached")
      end
    end

    context "when logged in as other user" do
      before { login_user(other_account) }

      it "denies access" do
        subject
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
      end

      it "does not attach the file" do
        expect { subject }.not_to change { ticket.reload.attachments.count }
      end
    end

    context "when no files selected" do
      before { login_user(creator_account) }

      subject { post :attach_files, params: {id: ticket.id} }

      it "sets an alert" do
        subject
        expect(flash[:alert]).to eq("No files selected")
      end

      it "redirects to the ticket" do
        expect(subject).to redirect_to(support_ticket_path(ticket))
      end
    end
  end

  describe "AI integration" do
    let(:valid_params) { {support_ticket: {title: "Test ticket", description: "A description", category: "account_access"}} }

    before { login_user(creator_account) }

    describe "POST #create" do
      it "starts the AI when enabled with an enabled playbook" do
        allow(SupportAiConfig).to receive(:enabled).and_return(true)
        create(:ai_playbook)

        expect { post :create, params: valid_params }.to have_enqueued_job(Support::AiProcessJob)
        created = Support::Ticket.unscoped.order(:id).last
        expect(created).to be_ai_analyzing
        expect(response).to redirect_to(support_ticket_url(created))
      end

      it "leaves the AI off by default" do
        expect { post :create, params: valid_params }.not_to have_enqueued_job(Support::AiProcessJob)
        expect(Support::Ticket.unscoped.order(:id).last).to be_ai_off
      end

      it "still renders the form again for invalid params" do
        post :create, params: {support_ticket: {title: "", description: "", category: "account_access"}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "POST #resolve_with_ai" do
      subject { post :resolve_with_ai, params: {id: ticket.id} }

      let(:ticket) { create(:ticket, :ai_awaiting_user, created: creator_account) }

      it "is authorized" do
        expect { subject }.to be_authorized_to(:resolve_with_ai?, ticket).with(Support::TicketPolicy).with_context(user: creator_account)
      end

      it "resolves the ticket and redirects with a notice" do
        subject
        expect(ticket.reload).to be_finished.and be_ai_resolved
        expect(response).to redirect_to(support_ticket_path(ticket))
        expect(flash[:notice]).to eq(I18n.t("support.tickets.resolved_with_ai"))
      end

      it "is denied for another account" do
        login_user(other_account)
        subject
        expect(ticket.reload).to be_open
        expect(flash[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
      end

      it "is denied when the AI is not waiting for the user" do
        ticket.update!(ai_state: :handoff_requested)
        subject
        expect(ticket.reload).to be_open
      end
    end

    describe "POST #request_human" do
      subject { post :request_human, params: {id: ticket.id} }

      let(:ticket) { create(:ticket, :ai_awaiting_user, created: creator_account) }

      before { stub_responder(summarize: ai_result("Summary")) }

      it "is authorized" do
        expect { subject }.to be_authorized_to(:request_human?, ticket).with(Support::TicketPolicy).with_context(user: creator_account)
      end

      it "hands off and redirects with a notice" do
        subject
        expect(ticket.reload).to be_ai_handoff_requested
        expect(response).to redirect_to(support_ticket_path(ticket))
        expect(flash[:notice]).to eq(I18n.t("support.tickets.human_requested"))
      end

      it "is denied once already handed off" do
        ticket.update!(ai_state: :handoff_requested)
        expect { subject }.not_to change { ticket.reload.updated_at }
      end

      it "is denied for another account" do
        login_user(other_account)
        subject
        expect(ticket.reload).to be_ai_awaiting_user
      end
    end
  end
end
