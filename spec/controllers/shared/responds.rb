# frozen_string_literal: true

RSpec.shared_examples "respond to missing" do
  it "responds with 404" do
    expect(subject).to have_http_status(404)
  end
end

RSpec.shared_examples "respond to success" do
  it "should responds with success" do
    expect(subject).to have_http_status(200)
  end
end

RSpec.shared_examples "respond with redirect" do
  it "should responds with redirect" do
    expect(subject).to have_http_status(302)
  end
end

RSpec.shared_examples "respond to invalid params" do
  it "should responds with 422" do
    expect(subject).to have_http_status(422)
    assert_select "div#error_explanation", 1
  end
end

RSpec.shared_examples "unauthenticated" do
  it "should add a flash message" do
    expect { subject }.to change { flash[:alert] }.from(nil).to(I18n.t("authentication.unauthenticated"))
  end
  it "should responds with redirect" do
    expect(subject).to have_http_status(302)
  end
  it "redirects to sign_in" do
    expect(subject).to redirect_to rodauth.login_path
  end
end

RSpec.shared_examples "unauthorized" do
  it "should add a flash message" do
    expect { subject }.to change { flash[:alert] }.from(nil).to(I18n.t("adminit.authorization.unauthorized"))
  end
  it "should responds with redirect" do
    expect(subject).to have_http_status(302)
  end
  it "redirects to root url" do
    expect(subject).to redirect_to root_url
  end
end

RSpec.shared_examples "adminit unauthenticated" do
  it "shouldn't add a flash message" do
    expect { subject }.not_to change { flash[:alert] }.from(nil)
  end
  it "should responds with redirect" do
    expect(subject).to have_http_status(302)
  end
  it "redirects to sign_in" do
    expect(subject).to redirect_to root_url
  end
end

RSpec.shared_examples "adminit unauthorized" do
  it "should add a flash message" do
    expect { subject }.not_to change { flash[:alert] }.from(nil)
  end
  it "should responds with redirect" do
    expect(subject).to have_http_status(302)
  end
  it "redirects to adminit url" do
    expect(subject).to redirect_to root_url
  end
end

RSpec.shared_context "user and permissions adminit" do
  let(:user) { create(:account, :with_role, :verified) }
  let(:user_superadmin) { create(:account, :superadmin, :verified) }
  let(:user_without_permissions) { create(:account, :with_role, :verified) }

  let(:app_permission) { create(:permission, roles: [user.role, user_superadmin.role]) }
  let(:permissions_permission) { create(:permission, resource: Adminit::PermissionPolicy.identifier, roles: [user_superadmin.role, user.role]) }
  let(:account_permission) { create(:permission, resource: Adminit::AccountPolicy.identifier, roles: [user_superadmin.role, user.role]) }
  let(:role_permission) { create(:permission, resource: Adminit::RolePolicy.identifier, roles: [user_superadmin.role, user.role]) }
end

RSpec.shared_context "adminit_auth" do
  context "when not logged" do
    it_behaves_like "adminit unauthenticated"
  end

  context "when logged" do
    context "without a role" do
      before do
        login_user(create(:account)) # login user
      end

      it_behaves_like "adminit unauthorized"
    end
  end
end
