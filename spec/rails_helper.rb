# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Prevent from running in non-test environment
abort("The Rails environment is running in #{Rails.env} mode!") unless Rails.env.test?

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

require "rspec/rails"
require "action_policy/rspec"

Rails.root.glob("spec/support/**/*.rb").each { |f| require f }
require Rails.root.join("spec/support/constants_helper")

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  # Add `travel_to`
  # See https://andycroll.com/ruby/replace-timecop-with-rails-time-helpers-in-rspec/
  config.include ActiveSupport::Testing::TimeHelpers

  config.after do
    # Make sure every example starts with the current time

    # Clear ActiveJob jobs
    if defined?(ActiveJob) && ActiveJob::QueueAdapters::TestAdapter === ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      ActiveJob::Base.queue_adapter.performed_jobs.clear
    end

    if defined?(ActionMailer)
      # Clear deliveries
      ActionMailer::Base.deliveries.clear
    end
  end
  config.include FactoryBot::Syntax::Methods

  config.include LoginHelpers::Controller, type: :controller
  config.include Rodauth::Rails::Test::Controller, type: :controller

  config.include Rodauth::Rails::Test::Request, type: :request
  config.include LoginHelpers::Request, type: :request
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
