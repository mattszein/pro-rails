require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::AudiencesController, type: :controller do
  include_context "user and permissions adminit"

  describe "GET #index" do
    subject { get :index }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        audience_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Audience).with(Adminit::AudiencePolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "paginates results" do
        subject
        expect(controller.instance_variable_get(:@pagy)).to be_a(Pagy)
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
        audience_permission
      end

      it "links an audience's name out of the table's turbo frame" do
        audience = create(:audience, name: "Beta testers")

        subject

        doc = Nokogiri::HTML5.parse(response.body)
        link = doc.at_css("a[href='#{adminit_audience_path(audience)}']")

        expect(link).not_to be_nil
        expect(link["data-turbo-frame"]).to eq("_top")
      end

      it "breaks the archive action out of the table's turbo frame" do
        create(:audience)

        subject

        doc = Nokogiri::HTML5.parse(response.body)
        archive_link = doc.at_css("a[data-turbo-method='patch']")

        expect(archive_link).not_to be_nil
        expect(archive_link["data-turbo-frame"]).to eq("_top")
      end

      it "breaks the unarchive action out of the table's turbo frame for an archived audience" do
        create(:audience, :archived)

        subject

        doc = Nokogiri::HTML5.parse(response.body)
        unarchive_link = doc.at_css("a[data-turbo-method='patch']")

        expect(unarchive_link.text).to eq(I18n.t("adminit.audiences.unarchive"))
        expect(unarchive_link["data-turbo-frame"]).to eq("_top")
      end
    end
  end

  describe "GET #show" do
    let(:audience) { create(:audience) }

    subject { get :show, params: {id: audience.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        audience_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, audience).with(Adminit::AudiencePolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"
    end
  end

  describe "GET #new" do
    subject { get :new }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        audience_permission
      end

      it_behaves_like "respond to success"

      it "seeds one condition row per registered condition" do
        subject
        audience = controller.instance_variable_get(:@audience)
        expect(audience.audience_conditions.map(&:condition_key)).to contain_exactly(
          "adminit_users", "roles", "verified_users", "registration_age"
        )
      end
    end
  end

  describe "POST #create" do
    subject { post :create, params: {audience: {name: "Probe audience"}} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        audience_permission
      end

      it "creates an audience with a :boolean condition" do
        params = {
          audience: {
            name: "Adminit-only audience",
            audience_conditions_attributes: {
              "0" => {condition_key: "adminit_users", enabled: "1", value: "true"}
            }
          }
        }

        expect { post :create, params: params }.to change(Audience, :count).by(1)
        audience = Audience.find_by(name: "Adminit-only audience")
        expect(audience.audience_conditions.sole.condition_key).to eq("adminit_users")
        expect(audience.audience_conditions.sole.value).to eq(true)
        expect(response).to redirect_to(adminit_audience_path(audience))
      end

      it "creates an audience with an :affirmative condition (no value control needed)" do
        params = {
          audience: {
            name: "Verified-only audience",
            audience_conditions_attributes: {
              "0" => {condition_key: "verified_users", enabled: "1"}
            }
          }
        }

        post :create, params: params
        audience = Audience.find_by(name: "Verified-only audience")
        expect(audience.audience_conditions.sole.value).to eq(true)
      end

      it "creates an audience with an :id_list condition" do
        role = create(:role)
        params = {
          audience: {
            name: "Role-based audience",
            audience_conditions_attributes: {
              "0" => {condition_key: "roles", enabled: "1", value: [role.id.to_s]}
            }
          }
        }

        post :create, params: params
        audience = Audience.find_by(name: "Role-based audience")
        expect(audience.audience_conditions.sole.value).to eq([role.id])
      end

      it "creates an audience with a :duration condition" do
        params = {
          audience: {
            name: "Old accounts audience",
            audience_conditions_attributes: {
              "0" => {condition_key: "registration_age", enabled: "1", value: {amount: "2", unit: "years"}}
            }
          }
        }

        post :create, params: params
        audience = Audience.find_by(name: "Old accounts audience")
        expect(audience.audience_conditions.sole.value).to eq({"amount" => "2", "unit" => "years"})
      end

      it "combines multiple enabled conditions into one audience (conjunction)" do
        params = {
          audience: {
            name: "Old verified accounts",
            audience_conditions_attributes: {
              "0" => {condition_key: "verified_users", enabled: "1"},
              "1" => {condition_key: "registration_age", enabled: "1", value: {amount: "1", unit: "years"}}
            }
          }
        }

        post :create, params: params
        audience = Audience.find_by(name: "Old verified accounts")
        expect(audience.audience_conditions.count).to eq(2)
      end

      # S26 — a name with every condition off is not saved.
      it "does not save an audience with no enabled conditions" do
        params = {
          audience: {
            name: "Empty audience",
            audience_conditions_attributes: {
              "0" => {condition_key: "adminit_users", enabled: "0"}
            }
          }
        }

        expect { post :create, params: params }.not_to change(Audience, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "ignores a condition_key the vocabulary does not declare" do
        params = {
          audience: {
            name: "Bogus condition audience",
            audience_conditions_attributes: {
              "0" => {condition_key: "not_a_real_condition", enabled: "1", value: "true"},
              "1" => {condition_key: "adminit_users", enabled: "1", value: "true"}
            }
          }
        }

        post :create, params: params
        audience = Audience.find_by(name: "Bogus condition audience")
        expect(audience.audience_conditions.map(&:condition_key)).to eq(["adminit_users"])
      end
    end
  end

  describe "PATCH #update" do
    let(:probe_audience) { create(:audience) }

    subject { patch :update, params: {id: probe_audience.id, audience: {name: probe_audience.name}} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        audience_permission
      end

      it "changes an existing condition's value" do
        audience = build(:audience, :without_condition)
        audience.audience_conditions.build(condition_key: "adminit_users", value: true)
        audience.save!
        condition = audience.audience_conditions.sole

        patch :update, params: {
          id: audience.id,
          audience: {
            name: audience.name,
            audience_conditions_attributes: {
              "0" => {id: condition.id, condition_key: "adminit_users", enabled: "1", value: "false"}
            }
          }
        }

        expect(audience.reload.audience_conditions.sole.value).to eq(false)
      end

      it "drops a condition when it is toggled off" do
        audience = build(:audience, :without_condition)
        audience.audience_conditions.build(condition_key: "adminit_users", value: true)
        audience.audience_conditions.build(condition_key: "verified_users", value: true)
        audience.save!
        adminit_condition = audience.audience_conditions.find_by(condition_key: "adminit_users")
        verified_condition = audience.audience_conditions.find_by(condition_key: "verified_users")

        patch :update, params: {
          id: audience.id,
          audience: {
            name: audience.name,
            audience_conditions_attributes: {
              "0" => {id: adminit_condition.id, condition_key: "adminit_users", enabled: "0"},
              "1" => {id: verified_condition.id, condition_key: "verified_users", enabled: "1"}
            }
          }
        }

        expect(audience.reload.audience_conditions.map(&:condition_key)).to eq(["verified_users"])
      end
    end
  end

  describe "PATCH #archive / PATCH #unarchive" do
    let(:audience) { create(:audience) }

    subject { patch :archive, params: {id: audience.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        audience_permission
      end

      it "archives without touching an attached flag's row (S18)" do
        flag = create(:feature_flag)
        create(:feature_flag_audience, feature_flag: flag, audience: audience)

        expect {
          patch :archive, params: {id: audience.id}
        }.not_to change { flag.reload.updated_at }

        expect(audience.reload).to be_archived
      end

      it "unarchives" do
        audience.archive!
        patch :unarchive, params: {id: audience.id}
        expect(audience.reload).not_to be_archived
      end
    end
  end

  # S30 — no admin path destroys an audience.
  describe "routes" do
    it "defines no destroy action" do
      expect(described_class.instance_methods(false)).not_to include(:destroy)
    end

    it "does not route DELETE against an audience" do
      expect { Rails.application.routes.recognize_path("/adminit/audiences/1", method: :delete) }
        .to raise_error(ActionController::RoutingError)
    end
  end
end
