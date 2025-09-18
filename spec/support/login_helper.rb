module LoginHelpers
  module Controller
    def login_user(account)
      rodauth.account_from_login(account.email)
      rodauth.login_session(TestConstants::TEST_PASSWORD)
    end

    def logout_user
      rodauth.logout
    end
  end
end
