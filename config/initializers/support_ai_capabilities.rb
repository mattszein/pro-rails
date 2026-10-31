# Re-installs the capability declarations (app/models/support/ai_capabilities.rb)
# on every code reload, so edits there hot-reload in development.
Rails.application.config.to_prepare do
  Support::AiCapabilities.install
end
