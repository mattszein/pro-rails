class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

  PROTECTED_PATHS = %w[/dashboard /account /settings /support /notifications].freeze
  PATH_LOCALES = (I18n.available_locales.map(&:to_s) - [I18n.default_locale.to_s]).freeze

  route do |r|
    # Handle locale-prefixed requests (e.g. /es/login, /es/dashboard)
    r.on PATH_LOCALES do |locale|
      rails_request.params[:locale] = locale
      rodauth.load_memory
      r.rodauth

      rodauth.require_account if r.path.start_with?(*PROTECTED_PATHS)
      break
    end

    # Handle default locale requests (no prefix)
    rodauth.load_memory
    r.rodauth

    rodauth.require_account if r.path.start_with?(*PROTECTED_PATHS)
  end
end
