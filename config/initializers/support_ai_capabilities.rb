# Re-installs the capability declarations (app/lib/support_ai/capabilities.rb)
# on every code reload, so edits there hot-reload in development.
Rails.application.config.to_prepare do
  SupportAi::Capabilities.install
end
