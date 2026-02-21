require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

RSpec.describe NotificationsController, type: :controller do
  let(:account) { create(:account, :verified) }

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
      before { login_user(account) }

      it_behaves_like "respond to success"

      it "is authorized" do
        expect { subject }.to be_authorized_to(:index?, :notification).with(NotificationPolicy).with_context(user: account)
      end
    end
  end

  describe "GET #user" do
    subject { get :user }

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
      before { login_user(account) }

      it_behaves_like "respond to success"

      it "is authorized" do
        expect { subject }.to be_authorized_to(:user?, :notification).with(NotificationPolicy).with_context(user: account)
      end
    end
  end

  describe "POST #mark_all_read" do
    subject { post :mark_all_read }

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
      before { login_user(account) }

      it "is authorized" do
        expect { subject }.to be_authorized_to(:mark_all_read?, :notification).with(NotificationPolicy).with_context(user: account)
      end

      it "marks all unread notifications as read" do
        create(:noticed_notification, recipient: account)
        create(:noticed_notification, recipient: account)

        expect { subject }.to change { account.notifications.unread.count }.from(2).to(0)
      end

      it "responds with ok" do
        subject
        expect(response).to have_http_status(:ok)
      end

      it "does not affect already read notifications" do
        read_notification = create(:noticed_notification, :read, recipient: account)
        original_read_at = read_notification.read_at

        subject

        expect(read_notification.reload.read_at).to be_within(1.second).of(original_read_at)
      end

      it "does not affect other users notifications" do
        other_account = create(:account, :verified)
        other_notification = create(:noticed_notification, recipient: other_account)

        subject

        expect(other_notification.reload.read_at).to be_nil
      end
    end
  end

  describe "POST #mark_as_read" do
    context "when not logged in" do
      it "redirects to login" do
        notification = create(:noticed_notification, recipient: account)
        expect(post(:mark_as_read, params: {id: notification.id})).to redirect_to(rodauth.login_path)
      end

      it "sets a flash alert" do
        notification = create(:noticed_notification, recipient: account)
        post :mark_as_read, params: {id: notification.id}
        expect(flash[:alert]).to eq("Please login to continue")
      end
    end

    context "when logged in" do
      before { login_user(account) }

      it "is authorized" do
        notification = create(:noticed_notification, recipient: account)
        expect { post :mark_as_read, params: {id: notification.id} }.to be_authorized_to(:mark_as_read?, a_kind_of(Noticed::Notification)).with(NotificationPolicy).with_context(user: account)
      end

      it "marks the notification as read" do
        notification = create(:noticed_notification, recipient: account)

        expect {
          post :mark_as_read, params: {id: notification.id}
        }.to change { notification.reload.read_at }.from(nil)
      end

      it "responds with ok" do
        notification = create(:noticed_notification, recipient: account)

        post :mark_as_read, params: {id: notification.id}
        expect(response).to have_http_status(:ok)
      end

      it "denies access when notification belongs to another user" do
        other_account = create(:account, :verified)
        other_notification = create(:noticed_notification, recipient: other_account)

        post :mark_as_read, params: {id: other_notification.id}
        expect(response).to have_http_status(:redirect)
      end

      it "redirects when notification does not exist" do
        post :mark_as_read, params: {id: 999999}
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
