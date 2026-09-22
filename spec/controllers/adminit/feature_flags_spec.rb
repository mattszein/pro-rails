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

      it "materializes a row for a declared flag with none yet" do
        with_feature_flag(:brand_new_flag) do
          expect { subject }.to change { FeatureFlag.exists?(key: "brand_new_flag") }.from(false).to(true)
        end
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

  # Controller specs don't render views by default (no render_views anywhere
  # in this app), so response.body is inert everywhere else in this file.
  # Scoped here, not file-wide, so the rest of the examples above keep
  # running without the extra render cost.
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
        # `to: :update?` resolves through ActionPolicy's default_rule to
        # `manage?` before it is applied/tracked — see
        # spec/policies/adminit/feature_flag_policy_spec.rb.
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

  # S30 — flags are not created or destroyed in Adminit: the controller
  # defines no new/create/edit/update/destroy action, and the routes expose
  # no such path either.
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
