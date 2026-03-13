source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
gem "pg", "~> 1.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
# gem "solid_cache" # Using Redis for caching
gem "solid_queue"
# gem "solid_cable" # Using AnyCable + Redis

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
gem "lexxy", "~> 0.1.26.beta"

gem "freezolite" # Freezolite add frozen_string_literals to true to every file in your project

gem "view_component", "~> 4.4"

gem "tailwindcss-rails", "~> 4.2"
gem "inline_svg"

gem "redis", "~> 5.4", ">= 5.4.1"
gem "anyway_config", "~> 2.0"
gem "anycable-rails", "~> 1.6"
gem "action_policy"

gem "dry-initializer-rails"
gem "interactor", "~> 3.0"

gem "mission_control-jobs"
gem "local_time"
gem "noticed", "~> 3.0"
gem "pagy", "~> 9.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "~> 8.0", require: false

  gem "rspec-rails"
  gem "rubocop-rspec"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "standard", ">= 1.35.1"
  gem "standard-rails"
  gem "erb_lint", require: false
  gem "htmlbeautifier"
  gem "lookbook", ">= 2.3.11"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "listen"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "cuprite", "0.17"
  gem "test-prof"
end

gem "rodauth-rails", "~> 2.1"
# Enables Sequel to use Active Record's database connection
gem "sequel-activerecord_connection", "~> 2.0", require: false
# Used by Rodauth for password hashing
gem "bcrypt", "~> 3.1", require: false
# Used by Rodauth for rendering built-in view and email templates
gem "tilt", "~> 2.4", require: false
