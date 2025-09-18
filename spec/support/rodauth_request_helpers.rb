require "active_support/concern"

module Rodauth
  module Rails
    module Test
      module Request
        # Provide access to rodauth in request specs
        def rodauth(name = nil)
          auth_class = Rodauth::Rails.app.rodauth(name)
          scope = auth_class.roda_class.new(rack_env)
          rodauth_instance = auth_class.new(scope)

          # Ensure session is initialized
          rodauth_instance.session # This forces session initialization
          rodauth_instance
        end

        private

        # Rack env is available via request.env after a request
        def rack_env
          raise "No request env available — make sure to call this after a request" if request.blank?

          # Ensure session is properly initialized in the environment
          env = request.env
          env["rack.session"] ||= {}
          env
        end
      end
    end
  end
end

# Simplified login helpers for request tests
module LoginHelpers
  module Request
    def login_user(account)
      # Use Rails built-in session handling
      post "/login", params: {
        email: account.email,
        password: TestConstants::TEST_PASSWORD
      }

      # Follow any redirects
      follow_redirect! while response.redirect?
    end

    def logout_user
      # Clear the session by making a request with empty session
      get "/", env: {"rack.session" => {}}
    end

    def logged_in?
      return false if request.blank?
      rodauth.logged_in?
    end

    def current_account
      return nil if request.blank?
      rodauth.account
    end
  end
end
