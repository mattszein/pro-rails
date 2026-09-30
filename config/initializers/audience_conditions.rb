# Re-installs the vocabulary (app/lib/audience_conditions/vocabulary.rb) on
# every code reload, so edits there hot-reload in development.
Rails.application.config.to_prepare do
  AudienceConditions::Vocabulary.install
end
