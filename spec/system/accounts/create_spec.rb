# frozen_string_literal: true

require "system_helper"

describe "Accounts -> New" do
  include ActiveJob::TestHelper

  it "I can create a new Account successfully" do
    visit "create-account"

    fill_in "email", with: "user@#{TestConstants::TEST_EMAIL_DOMAIN}"
    fill_in "password", with: TestConstants::TEST_PASSWORD
    fill_in "password-confirm", with: TestConstants::TEST_PASSWORD

    expect {
      click_button "Register"
    }.to change(Account, :count).by(1)
    # check "user[terms_of_service]"
    #
    expect(page).to have_content "An email has been sent to you with a link to verify your account"
    expect(page).to have_content("verify")
  end
end
