require "system_helper"

RSpec.describe "Profile settings", type: :system do
  let(:account) { create(:account, :verified) }

  before do
    login_as(account)
  end

  it "updates the profile" do
    visit edit_settings_profile_path

    fill_in "Username", with: "janedoe"
    fill_in "Bio", with: "This is my new bio."
    attach_file "profile[avatar]", Rails.root.join("spec/fixtures/files/avatar.png")

    click_on "Save Profile"

    expect(page).to have_content("Profile updated successfully")
    expect(page).to have_field("Username", with: "janedoe")
    expect(page).to have_field("Bio", with: "This is my new bio.")
    expect(page).to have_css("img.rounded-full")
  end

  it "shows validation errors" do
    visit edit_settings_profile_path

    fill_in "Username", with: "invalid username!"

    click_on "Save Profile"

    expect(page).to have_content("can only contain letters, numbers, and underscores")
  end
end
