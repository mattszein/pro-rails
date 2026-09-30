require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::FeatureFlagsController, type: :controller do
  include_context "user and permissions adminit"

  describe "GET #index" do
    subject { get :index }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, FeatureFlag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "paginates declared flags" do
        subject
        expect(controller.instance_variable_get(:@pagy)).to be_a(Pagy)
      end

      it "excludes rows whose key is not declared" do
        undeclared = create(:feature_flag, key: "undeclared_flag")
        FeatureFlags::Registry.registry.delete(:undeclared_flag)

        subject
        expect(controller.instance_variable_get(:@feature_flags)).not_to include(undeclared)
      end

      context "with an access-state filter" do
        it "filters to open flags" do
          open_flag = create(:feature_flag, key: "open_for_filter")
          create(:feature_flag_account, :allowed, feature_flag: open_flag)
          empty_flag = create(:feature_flag, key: "empty_for_filter")

          get :index, params: {filter: {access_state: "open"}}

          flags = controller.instance_variable_get(:@feature_flags)
          expect(flags).to include(open_flag)
          expect(flags).not_to include(empty_flag)
        end
      end
    end
  end

  # Controller specs don't render views by default, so response.body is
  # inert everywhere else in this file — scoped here to keep the extra
  # render cost off the rest of the examples.
  describe "GET #index (rendered)" do
    render_views

    subject { get :index }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "links a flag's name out of the table's turbo frame" do
        with_feature_flag(:some_flag) do
          flag = create(:feature_flag, key: "some_flag")

          subject

          doc = Nokogiri::HTML5.parse(response.body)
          link = doc.at_css("a[href='#{adminit_feature_flag_path(flag)}']")

          expect(link).not_to be_nil
          expect(link["data-turbo-frame"]).to eq("_top")
        end
      end
    end
  end

  describe "GET #show" do
    let(:flag) { create(:feature_flag) }

    subject { get :show, params: {id: flag.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "renders successfully with an attached audience (condition summary + link)" do
        create(:feature_flag_audience, feature_flag: flag, audience: create(:audience))
        get :show, params: {id: flag.id}
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #audience_select" do
    let(:flag) { create(:feature_flag) }

    subject { get :audience_select, params: {id: flag.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "assigns only active, unattached audiences" do
        attachable = create(:audience)
        archived = create(:audience, :archived)
        attached = create(:audience)
        create(:feature_flag_audience, feature_flag: flag, audience: attached)

        subject

        result = controller.instance_variable_get(:@attachable_audiences)
        expect(result).to include(attachable)
        expect(result).not_to include(archived, attached)
      end
    end
  end

  describe "GET #account_select" do
    let(:flag) { create(:feature_flag) }

    subject { get :account_select, params: {id: flag.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"
    end
  end

  describe "POST #attach_audience" do
    let(:flag) { create(:feature_flag) }
    let(:audience) { create(:audience) }

    subject { post :attach_audience, params: {id: flag.id, audience_id: audience.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond with redirect"

      it "attaches the audience and shows a success flash" do
        subject
        expect(flag.reload.audiences).to include(audience)
        expect(flash[:notice]).to be_present
      end

      # An archived audience is not offered when attaching, and the
      # controller rejects one submitted directly, not only omits it.
      it "rejects an archived audience_id, even submitted directly" do
        archived = create(:audience, :archived)

        post :attach_audience, params: {id: flag.id, audience_id: archived.id}

        expect(flag.reload.audiences).not_to include(archived)
        expect(response).to have_http_status(:found)
      end

      it "rejects an audience_id already attached to this flag" do
        create(:feature_flag_audience, feature_flag: flag, audience: audience)

        expect {
          post :attach_audience, params: {id: flag.id, audience_id: audience.id}
        }.not_to change(FeatureFlagAudience, :count)
      end
    end
  end

  describe "DELETE #detach_audience" do
    let(:flag) { create(:feature_flag) }
    let(:audience) { create(:audience) }

    subject { delete :detach_audience, params: {id: flag.id, audience_id: audience.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
        create(:feature_flag_audience, feature_flag: flag, audience: audience)
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond with redirect"

      it "detaches the audience and shows a success flash" do
        subject
        expect(flag.reload.audiences).not_to include(audience)
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "POST #add_account" do
    let(:flag) { create(:feature_flag) }
    let(:account) { create(:account) }

    subject { post :add_account, params: {id: flag.id, account_id: account.id, access: "allowed"} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond with redirect"

      it "adds the account entry and shows a success flash" do
        subject
        entry = flag.reload.account_entries.find_by(account: account)
        expect(entry).to be_allowed
        expect(flash[:notice]).to be_present
      end

      it "updates an existing entry's access in place" do
        entry = create(:feature_flag_account, :allowed, feature_flag: flag, account: account)

        post :add_account, params: {id: flag.id, account_id: account.id, access: "blocked"}

        reloaded = flag.account_entries.find_by(account: account)
        expect(reloaded.id).to eq(entry.id)
        expect(reloaded).to be_blocked
      end
    end
  end

  describe "DELETE #remove_account" do
    let(:flag) { create(:feature_flag) }
    let(:account) { create(:account) }

    subject { delete :remove_account, params: {id: flag.id, account_id: account.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
        create(:feature_flag_account, :allowed, feature_flag: flag, account: account)
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond with redirect"

      it "removes the account entry and shows a success flash" do
        subject
        expect(flag.reload.account_entries.exists?(account: account)).to be false
        expect(flash[:notice]).to be_present
      end
    end
  end

  # Flags are not created or destroyed in Adminit: the controller defines
  # no new/create/edit/update/destroy action, and the routes expose none.
  describe "routes" do
    it "defines no new, create, edit, update, or destroy action" do
      expect(described_class.instance_methods(false)).not_to include(:new, :create, :edit, :update, :destroy)
    end

    it "exposes no new or edit path" do
      expect { Rails.application.routes.url_helpers.new_adminit_feature_flag_path }
        .to raise_error(NoMethodError)
      expect { Rails.application.routes.url_helpers.edit_adminit_feature_flag_path(1) }
        .to raise_error(NoMethodError)
    end

    it "does not route POST/PATCH/DELETE against the flags collection or member" do
      expect { Rails.application.routes.recognize_path("/adminit/feature_flags", method: :post) }
        .to raise_error(ActionController::RoutingError)
      expect { Rails.application.routes.recognize_path("/adminit/feature_flags/1", method: :patch) }
        .to raise_error(ActionController::RoutingError)
      expect { Rails.application.routes.recognize_path("/adminit/feature_flags/1", method: :delete) }
        .to raise_error(ActionController::RoutingError)
    end
  end
end
