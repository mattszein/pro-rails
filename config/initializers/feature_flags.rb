# Re-installs the flag declarations (app/lib/feature_flags/flags.rb) on
# every code reload, so edits there hot-reload in development.
Rails.application.config.to_prepare do
  FeatureFlags::Flags.install
end
