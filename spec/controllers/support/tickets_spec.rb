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
      end
    end
  end

  describe "GET #edit" do
    context "when not logged in" do
      it "redirects to login" do
        expect(get(:edit, params: {id: ticket.id})).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in as ticket creator" do
      before { login_user(creator_account) }

      it "redirects non-turbo-frame requests to root" do
        expect(get(:edit, params: {id: ticket.id})).to redirect_to(root_path)
      end

      context "with turbo frame request" do
        before { @request.headers["Turbo-Frame"] = "modal" }

        subject { get :edit, params: {id: ticket.id} }

        it_behaves_like "respond to success"

        it "is authorized" do
          expect { subject }.to be_authorized_to(:update?, ticket).with(Support::TicketPolicy).with_context(user: creator_account)
        end
      end
    end

    context "when logged in as other user" do
      before do
        login_user(other_account)
        @request.headers["Turbo-Frame"] = "modal"
      end

      it "denies access" do
        get :edit, params: {id: ticket.id}
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
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

  describe "PATCH #update" do
    let(:update_params) { {id: ticket.id, support_ticket: {title: "Updated title"}} }

    subject { patch :update, params: update_params }

    context "when not logged in" do
      it "redirects to login" do
        expect(subject).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in as ticket creator" do
      before { login_user(creator_account) }

      it "is authorized" do
        expect { subject }.to be_authorized_to(:update?, ticket).with(Support::TicketPolicy).with_context(user: creator_account)
      end

      it "updates the ticket" do
        subject
        expect(ticket.reload.title).to eq("Updated title")
      end

      it "redirects after update" do
        expect(subject).to have_http_status(:redirect)
      end
    end

    context "when logged in as other user" do
      before { login_user(other_account) }

      it "denies access" do
        subject
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq(I18n.t("adminit.authorization.unauthorized"))
      end

      it "does not update the ticket" do
        subject
        expect(ticket.reload.title).not_to eq("Updated title")
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
end
