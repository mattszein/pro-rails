require "rails_helper"

RSpec.describe "FeatureGated", type: :request do
  # No production controller is gated yet, so this exercises the concern
  # through a demo controller mounted on a route local to this spec; login
  # happens against the real routes before the demo route is swapped in.
  before do
    stub_const("FeatureGatedDemoController", Class.new(SharedBaseController) {
      before_action { require_feature!(:demo_flag) }

      def show
        render json: {status: "granted"}
      end
    })
  end

  after { Rails.application.reload_routes! }

  around { |example| with_feature_flag(:demo_flag) { example.run } }

  def draw_demo_route!
    Rails.application.routes.draw do
      get "/__feature_gated_demo", to: "feature_gated_demo#show"
    end
  end

  def get_demo
    get "/__feature_gated_demo", as: :json
  end

  it "is 404 for a signed-out request, indistinguishable from a nonexistent page" do
    draw_demo_route!
    get_demo

    expect(response).to have_http_status(:not_found)
  end

  it "is 404 when the flag has an empty access list" do
    account = create(:account, :verified)
    create(:feature_flag, key: "demo_flag")
    login_user(account)

    draw_demo_route!
    get_demo

    expect(response).to have_http_status(:not_found)
  end

  it "is 200 when an attached audience matches" do
    account = create(:account, :verified)
    flag = create(:feature_flag, key: "demo_flag")
    audience = build(:audience, :without_condition)
    audience.audience_conditions.build(condition_key: "verified_users", value: true)
    audience.save!
    create(:feature_flag_audience, feature_flag: flag, audience: audience)
    login_user(account)

    draw_demo_route!
    get_demo

    expect(response).to have_http_status(:ok)
  end

  it "is 200 when explicitly allowed, even without a matching audience" do
    account = create(:account, :verified)
    flag = create(:feature_flag, key: "demo_flag")
    create(:feature_flag_account, :allowed, feature_flag: flag, account: account)
    login_user(account)

    draw_demo_route!
    get_demo

    expect(response).to have_http_status(:ok)
  end

  it "is 404 again once the granting audience is detached" do
    account = create(:account, :verified)
    flag = create(:feature_flag, key: "demo_flag")
    audience = build(:audience, :without_condition)
    audience.audience_conditions.build(condition_key: "verified_users", value: true)
    audience.save!
    join = create(:feature_flag_audience, feature_flag: flag, audience: audience)
    login_user(account)
    draw_demo_route!

    get_demo
    expect(response).to have_http_status(:ok)

    join.destroy
    get_demo
    expect(response).to have_http_status(:not_found)
  end

  it "is 404 again once the allowed account entry is removed" do
    account = create(:account, :verified)
    flag = create(:feature_flag, key: "demo_flag")
    entry = create(:feature_flag_account, :allowed, feature_flag: flag, account: account)
    login_user(account)
    draw_demo_route!

    get_demo
    expect(response).to have_http_status(:ok)

    entry.destroy
    get_demo
    expect(response).to have_http_status(:not_found)
  end

  it "reflects a role change on the very next request" do
    matching_role = create(:role)
    other_role = create(:role)
    account = create(:account, :verified, role: matching_role)
    flag = create(:feature_flag, key: "demo_flag")
    audience = build(:audience, :without_condition)
    audience.audience_conditions.build(condition_key: "roles", value: [matching_role.id])
    audience.save!
    create(:feature_flag_audience, feature_flag: flag, audience: audience)
    login_user(account)
    draw_demo_route!

    get_demo
    expect(response).to have_http_status(:ok)

    account.update!(role: other_role)
    get_demo
    expect(response).to have_http_status(:not_found)
  end
end
