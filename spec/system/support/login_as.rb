module SystemLoginHelpers
  def login_as(account, password: TestConstants::TEST_PASSWORD)
    visit "/login"
    fill_in "email", with: account.email
    fill_in "password", with: password
    click_button "Login"
  end
end

RSpec.configure do |config|
  config.include SystemLoginHelpers, type: :system
end
