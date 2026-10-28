require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::AiPlaybooksController, type: :controller do
  include_context "user and permissions adminit"
  render_views

  let(:permitted) { support_ai_permission }
  let(:policy) { Adminit::AiPlaybookPolicy }

  describe "GET #index" do
    subject { get :index }

    include_context "adminit_auth"

    context "when logged with permission" do
      let!(:custom) { create(:ai_playbook, name: "Billing flow", category_keys: ["billing"], min_priority: 2) }
      let!(:default) { create(:ai_playbook, :default, name: "Default") }

      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Support::AiPlaybook).with(policy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "lists custom playbooks by name and the default last" do
        subject
        expect(controller.instance_variable_get(:@playbooks)).to eq([custom, default])
      end

      it "renders the rows" do
        subject
        expect(response.body).to include("Billing flow")
        expect(response.body).to include(I18n.t("adminit.ai_playbooks.default_badge"))
        expect(response.body).to include(I18n.t("adminit.ai_playbooks.specificity"))
      end
    end
  end

  describe "GET #new" do
    subject { get :new }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:create?, Support::AiPlaybook).with(policy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "renders registry capabilities grouped by kind with defaults checked" do
        subject
        Support::AiCapabilities.keys.each do |key|
          assert_select "input[type=checkbox][name='support_ai_playbook[capabilities][]'][value=#{key}]", 1
        end
        assert_select "input[value=account_facts][checked]", 1
        assert_select "input[value=similar_tickets][checked]", 0
        expect(response.body).to include(I18n.t("adminit.ai_playbooks.group_context"), I18n.t("adminit.ai_playbooks.group_tool"), I18n.t("adminit.ai_playbooks.group_flag"))
      end

      it "shows the conditions section" do
        subject
        assert_select "input[name='support_ai_playbook[category_keys][]'][value=billing]", 1
        assert_select "select[name='support_ai_playbook[min_priority]']", 1
        assert_select "select[name='support_ai_playbook[audience_id]']", 1
      end
    end
  end

  describe "GET #edit" do
    let(:playbook) { create(:ai_playbook, capabilities: %w[past_tickets]) }

    subject { get :edit, params: {id: playbook.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, playbook).with(policy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "checks the playbook's capabilities" do
        subject
        assert_select "input[value=past_tickets][checked]", 1
        assert_select "input[value=account_facts][checked]", 0
      end

      context "with the default playbook" do
        let(:playbook) { create(:ai_playbook, :default) }

        it "does not render condition fields" do
          subject
          assert_select "input[name='support_ai_playbook[category_keys][]']", 0
          assert_select "select[name='support_ai_playbook[min_priority]']", 0
          assert_select "select[name='support_ai_playbook[audience_id]']", 0
          expect(response.body).to include(I18n.t("adminit.ai_playbooks.conditions_locked"))
        end
      end
    end
  end

  describe "POST #create" do
    let(:audience) { create(:audience) }
    let(:valid_params) do
      {support_ai_playbook: {
        name: "Technical", enabled: "1", mode: "triage_only", instructions: "Be brief.",
        category_keys: ["", "technical_issue"], min_priority: "2", max_priority: "4", audience_id: audience.id,
        capabilities: ["", "account_facts", "investigate_note"],
        max_ai_turns: "3", idle_reminder_after_hours: "12", idle_handoff_after_hours: "24"
      }}
    end
    let(:invalid_params) { {support_ai_playbook: {name: ""}} }

    subject { post :create, params: valid_params }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Support::AiPlaybook).with(policy).with_context(user: user)
      end

      it "creates the playbook with all submitted fields" do
        expect { subject }.to change(Support::AiPlaybook, :count).by(1)
        playbook = Support::AiPlaybook.order(:id).last
        expect(playbook).to have_attributes(
          name: "Technical", mode: "triage_only", min_priority: 2, max_priority: 4, audience_id: audience.id,
          capabilities: %w[account_facts investigate_note], max_ai_turns: 3, is_default: false
        )
        expect(playbook.category_keys).to eq(["technical_issue"])
      end

      it "redirects to the index" do
        expect(subject).to redirect_to(adminit_ai_playbooks_path)
      end

      it "never lets a request create a default playbook" do
        post :create, params: {support_ai_playbook: valid_params[:support_ai_playbook].merge(is_default: "1")}
        expect(Support::AiPlaybook.order(:id).last).not_to be_is_default
      end

      context "with an unregistered capability" do
        subject { post :create, params: {support_ai_playbook: valid_params[:support_ai_playbook].merge(capabilities: ["hack"])} }

        it "does not create and returns 422" do
          expect { subject }.not_to change(Support::AiPlaybook, :count)
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "with invalid params" do
        subject { post :create, params: invalid_params }

        it_behaves_like "respond to invalid params"

        it "does not create a playbook" do
          expect { subject }.not_to change(Support::AiPlaybook, :count)
        end
      end
    end
  end

  describe "PATCH #update" do
    let(:playbook) { create(:ai_playbook, name: "Old") }
    let(:params) { {id: playbook.id, support_ai_playbook: {name: "New", capabilities: ["", "past_tickets"]}} }

    subject { patch :update, params: params }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, playbook).with(policy).with_context(user: user)
      end

      it "updates the playbook" do
        subject
        expect(playbook.reload).to have_attributes(name: "New", capabilities: ["past_tickets"])
      end

      it "clears the capabilities when none are checked" do
        patch :update, params: {id: playbook.id, support_ai_playbook: {capabilities: [""]}}
        expect(playbook.reload.capabilities).to eq([])
      end

      it "redirects to the index" do
        expect(subject).to redirect_to(adminit_ai_playbooks_path)
      end

      context "with invalid params" do
        let(:params) { {id: playbook.id, support_ai_playbook: {name: ""}} }

        it_behaves_like "respond to invalid params"

        it "does not update" do
          expect { subject }.not_to change { playbook.reload.name }
        end
      end

      context "with the default playbook" do
        let(:playbook) { create(:ai_playbook, :default, name: "Default") }
        let(:params) do
          {id: playbook.id, support_ai_playbook: {
            name: "Fallback", category_keys: ["billing"], min_priority: "3", max_priority: "4",
            audience_id: create(:audience).id, is_default: "0"
          }}
        end

        it "updates editable fields" do
          expect { subject }.to change { playbook.reload.name }.to("Fallback")
        end

        it "does not change the locked conditions" do
          subject
          playbook.reload
          expect(playbook.categories).to eq([])
          expect(playbook.min_priority).to be_nil
          expect(playbook.max_priority).to be_nil
          expect(playbook.audience_id).to be_nil
        end

        it "stays the default" do
          subject
          expect(playbook.reload).to be_is_default
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:playbook) { create(:ai_playbook) }

    subject { delete :destroy, params: {id: playbook.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, playbook).with(policy).with_context(user: user)
      end

      it "destroys a non-default playbook" do
        expect { subject }.to change(Support::AiPlaybook, :count).by(-1)
        expect(response).to redirect_to(adminit_ai_playbooks_path)
        expect(flash[:notice]).to be_present
      end

      context "with the default playbook" do
        let!(:playbook) { create(:ai_playbook, :default) }

        it "is blocked with an alert" do
          expect { subject }.not_to change(Support::AiPlaybook, :count)
          expect(response).to redirect_to(adminit_ai_playbooks_path)
          expect(flash[:alert]).to include(I18n.t("activerecord.errors.models.support/ai_playbook.attributes.base.cannot_destroy_default"))
        end
      end
    end
  end

  describe "POST #toggle" do
    let(:playbook) { create(:ai_playbook, enabled: true) }

    subject { post :toggle, params: {id: playbook.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, playbook).with(policy).with_context(user: user)
      end

      it "disables an enabled playbook" do
        expect { subject }.to change { playbook.reload.enabled }.from(true).to(false)
        expect(response).to redirect_to(adminit_ai_playbooks_path)
      end

      it "enables a disabled playbook" do
        playbook.update!(enabled: false)
        expect { subject }.to change { playbook.reload.enabled }.from(false).to(true)
      end

      it "can disable the default playbook" do
        default = create(:ai_playbook, :default)
        expect { post :toggle, params: {id: default.id} }.to change { default.reload.enabled }.to(false)
      end
    end
  end

  describe "authorization" do
    let!(:playbook) { create(:ai_playbook) }

    context "when logged without the support_ai permission" do
      before do
        login_user(user)
        app_permission
      end

      it "rejects index" do
        expect(get(:index)).to redirect_to(root_url)
      end

      it "does not create playbooks" do
        expect { post :create, params: {support_ai_playbook: {name: "x"}} }.not_to change(Support::AiPlaybook, :count)
      end

      it "does not toggle or destroy" do
        post :toggle, params: {id: playbook.id}
        expect { delete :destroy, params: {id: playbook.id} }.not_to change(Support::AiPlaybook, :count)
        expect(playbook.reload.enabled).to be(true)
      end
    end
  end
end
