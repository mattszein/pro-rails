require "system_helper"

# NOTE: exercised against a headless-Chrome-backed Capybara driver, same as
# every other spec/system/** spec — not runnable standalone without the
# `chrome` compose service and a reachable app server alongside it.
RSpec.describe "Adminit audiences", type: :system do
  let(:role) { create(:role, name: "audience_admin") }
  let(:account) { create(:account, :verified, role: role) }

  before do
    create(:permission, resource: :audience, roles: [role])
    login_as(account)
  end

  describe "creating an audience" do
    it "saves a :boolean condition (adminit_users)" do
      visit new_adminit_audience_path
      fill_in "audience[name]", with: "Adminit-only users"

      check "audience[audience_conditions_attributes][0][enabled]"
      choose "audience[audience_conditions_attributes][0][value]", option: "true"

      click_button I18n.t("shared.common.save")

      expect(page).to have_content("Adminit-only users")
      audience = Audience.find_by(name: "Adminit-only users")
      expect(audience.audience_conditions.sole.condition_key).to eq("adminit_users")
    end

    it "saves an :affirmative condition (verified_users) with no value control" do
      visit new_adminit_audience_path
      fill_in "audience[name]", with: "Verified users only"

      check "audience[audience_conditions_attributes][2][enabled]"

      click_button I18n.t("shared.common.save")

      audience = Audience.find_by(name: "Verified users only")
      expect(audience.audience_conditions.sole.value).to eq(true)
    end

    it "saves an :id_list condition (roles)" do
      target_role = create(:role, name: "Support")
      visit new_adminit_audience_path
      fill_in "audience[name]", with: "Support role members"

      check "audience[audience_conditions_attributes][1][enabled]"
      select target_role.name, from: "audience[audience_conditions_attributes][1][value][]"

      click_button I18n.t("shared.common.save")

      audience = Audience.find_by(name: "Support role members")
      expect(audience.audience_conditions.sole.value).to eq([target_role.id])
    end

    it "saves a :duration condition (registration_age)" do
      visit new_adminit_audience_path
      fill_in "audience[name]", with: "Long-time accounts"

      check "audience[audience_conditions_attributes][3][enabled]"
      fill_in "audience[audience_conditions_attributes][3][value][amount]", with: "2"
      select I18n.t("audience_conditions.registration_age.units.years"),
        from: "audience[audience_conditions_attributes][3][value][unit]"

      click_button I18n.t("shared.common.save")

      audience = Audience.find_by(name: "Long-time accounts")
      expect(audience.audience_conditions.sole.value).to eq({"amount" => "2", "unit" => "years"})
    end

    it "refuses to save with every condition left off" do
      visit new_adminit_audience_path
      fill_in "audience[name]", with: "Nothing selected"

      click_button I18n.t("shared.common.save")

      expect(Audience.exists?(name: "Nothing selected")).to be false
      expect(page).to have_content("prevented this from being saved")
    end

    it "has no flag creation entry point reachable from the audiences UI" do
      visit adminit_audiences_path
      expect(page).not_to have_link(href: /new_adminit_feature_flag/)
    end
  end

  describe "editing an audience" do
    it "saves a change to an existing condition's value" do
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "adminit_users", value: true)
      audience.save!

      visit edit_adminit_audience_path(audience)
      choose "audience[audience_conditions_attributes][0][value]", option: "false"
      click_button I18n.t("shared.common.save")

      expect(audience.reload.audience_conditions.sole.value).to eq(false)
    end
  end

  describe "archiving" do
    it "keeps the capability granted after archiving" do
      flag_key = :audiences_system_spec_flag
      with_feature_flag(flag_key) do
        flag = create(:feature_flag, key: flag_key.to_s)
        audience = build(:audience, :without_condition)
        audience.audience_conditions.build(condition_key: "verified_users", value: true)
        audience.save!
        create(:feature_flag_audience, feature_flag: flag, audience: audience)
        matching_account = create(:account, :verified)

        visit adminit_audience_path(audience)
        accept_confirm { click_button I18n.t("adminit.audiences.archive") }

        expect(audience.reload).to be_archived
        expect(FeatureFlags.enabled?(flag_key, matching_account)).to be true
      end
    end

    it "omits an archived audience from the flag attach list" do
      archived = create(:audience, :archived)
      flag = create(:feature_flag)

      visit audience_select_adminit_feature_flag_path(flag)
      expect(page).not_to have_select("audience_id", with_options: [archived.name])
    end
  end

  it "shows zero declared-flag usage for an audience whose only flag has retired" do
    retired_key = :audiences_system_spec_retired_flag
    flag = create(:feature_flag, key: retired_key.to_s)
    audience = create(:audience)
    create(:feature_flag_audience, feature_flag: flag, audience: audience)
    FeatureFlags::Registry.registry.delete(retired_key)

    visit adminit_audiences_path
    within("tr", text: audience.name) do
      expect(page).to have_content("0")
    end
  end
end
