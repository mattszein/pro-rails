# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pro-Rails is a Rails 8.0 application using modern Rails stack with Hotwire (Turbo/Stimulus), ViewComponent architecture, and a role-based access control (RBAC) admin system called "Adminit".

## Tech Stack

- **Rails**: 8.0.2 with PostgreSQL
- **Frontend**: Hotwire (Turbo, Stimulus), TailwindCSS 4.2, Propshaft (asset pipeline)
- **Authentication**: Rodauth with multi-phase login and email auth
- **Authorization**: ActionPolicy with custom RBAC system
- **Components**: ViewComponent with custom form builder
- **WebSockets**: AnyCable for Action Cable
- **Solid Stack**: SolidCache, SolidQueue, SolidCable for Rails infrastructure
- **Testing**: RSpec with FactoryBot, Shoulda-Matchers, Capybara + Cuprite for system tests
- **Code Quality**: Standard Ruby linter, Brakeman for security scanning
- **Code Conventions**: Freezolite auto-adds frozen_string_literals (disabled in test environment)

## Development Commands

### Setup
```bash
bin/setup                    # Initial setup
bin/dev                      # Start development server with all services
```

### Testing
```bash
bundle exec rspec                                    # Run all tests
bundle exec rspec spec/models/account_spec.rb        # Run single spec file
bundle exec rspec spec/models/account_spec.rb:10     # Run single test at line 10
bundle exec rspec --tag ~type:system                 # Run all except system tests (used in CI)
```

### Database
```bash
bin/rails db:prepare         # Setup database (create + migrate)
bin/rails db:migrate         # Run migrations
bin/rails db:seed            # Seed database
bin/rails db:test:prepare    # Prepare test database
```

### Linting & Security
```bash
bin/rubocop                  # Lint Ruby code (uses Standard)
bin/rubocop -a               # Auto-fix linting issues
bin/brakeman                 # Security vulnerability scan
bin/importmap audit          # Check JS dependencies for vulnerabilities
./erb_linter.sh              # Lint ERB templates
```

### Component Development
```bash
# Lookbook is available in development at /lookbook for component previews
# Components are in app/components/core/
```

## Architecture & Key Patterns

### Authentication (Rodauth)
- Configured in `app/misc/rodauth_main.rb` and `app/misc/rodauth_app.rb`
- Uses `Account` model with email-based authentication
- Multi-phase login enabled
- Features: create_account, verify_account, login, logout, remember, reset_password, change_password, change_login, verify_login_change, close_account, email_auth
- Account statuses: unverified (1), verified (2), closed (3)
- Login helpers available in specs: see `spec/rails_helper.rb` for `LoginHelpers::Controller` and `LoginHelpers::Request`

### Authorization (ActionPolicy + RBAC)
- Base policy: `app/policies/application_policy.rb`
- Admin area uses specialized policies in `app/policies/adminit/` with resource-based permissions
- Permission model controls access via `permissions_roles` join table
- Access check: `user.role.permissions.exists?(resource: key)`
- Accounts need a role to access adminit area (checked by `Account#adminit_access?`)
- "superadmin" role has special privileges

### Models & Database
- **Account**: User model with Rodauth integration, belongs_to role
- **Role**: has_many accounts, has_and_belongs_to_many permissions
- **Permission**: has_and_belongs_to_many roles, resource-based authorization
- **Ticket**: Example domain model with creator/assignee relationships to accounts
- PostgreSQL extensions: citext (case-insensitive text), plpgsql

### ViewComponent Architecture
- Custom form builder: `CustomFormBuilder` (extends `ViewComponent::Form::Builder`)
- Form components namespace: `Core::Form::*` (MaterialInput, Button, Toggle, Counter, etc.)
- Components in `app/components/core/` with corresponding CSS/JS in component directories
- Autoloaded from `app/components` path
- Component previews available via Lookbook in development

### Adminit (Admin Area)
- Namespace: `/adminit` routes (see `config/routes/adminit.rb`)
- Base controller: `Adminit::ApplicationController` with authorization checks
- Manages: accounts, tickets, roles (with account assignment), permissions
- Protected by `authorize_adminit_access` before_action (requires role)
- Uses ActionPolicy for granular permission checks per resource
- Uses CustomFormBuilder for all forms

### Configuration
- Config classes use Anyway Config pattern (see `config/configs/application_config.rb`)
- AWS config available at `config/configs/aws_config.rb`
- AnyCable configured via `anycable.toml`

### Testing Strategy
- RSpec for all tests (no Minitest)
- FactoryBot for test data
- Shoulda-Matchers for model validation tests
- Cuprite (Chrome headless) for system tests
- TestProf for test performance analysis
- Login helpers integrated for controller and request specs
- ActionPolicy RSpec matchers available

## File Generation Conventions
Rails generators are configured to skip generating:
- Asset files
- Helper files
- Stylesheets
- JavaScripts
- Test framework files (RSpec is manually configured)

Create components manually or use ViewComponent generators.

## CI/CD Pipeline
GitHub Actions runs four jobs on PRs and main branch:
1. **scan_ruby**: Brakeman security scan (`bin/brakeman --no-pager`)
2. **scan_js**: JavaScript dependency audit (`bin/importmap audit`)
3. **lint**: Ruby code linting (`bin/rubocop -f github`)
4. **test**: RSpec test suite with PostgreSQL, Redis, and AnyCable services

Required environment variables for tests:
- DB_USERNAME, DB_PASSWORD, DB_HOST, DB_PORT
- REDIS_URL
- ANYCABLE_SECRET, ANYCABLE_WEBSOCKET_URL
- FREEZOLITE_DISABLED=true (for test environment)

## Important Patterns

### Custom Form Components
When building forms, use the CustomFormBuilder methods which render ViewComponents:
- `form.text_field`, `form.password_field`, `form.number_field` → MaterialInput component
- `form.text_area` → TextArea component
- `form.button` → Button component (supports theme, size, fullw options)
- `form.toggle`, `form.check_box` → Toggle/CheckBox components
- `form.labeled` → Labeled wrapper component
- `form.code` → Code input component
- `form.counter` → Counter component

### Rodauth Integration
- Current user available as `rodauth.rails_account` or `current_account`
- Test helpers: `rodauth.login(account)` in request/controller specs
- Account status enum used throughout: `:unverified`, `:verified`, `:closed`

### ActionPolicy Authorization
- Policies define rules using `def manage?`, `def index?`, etc.
- Adminit policies check permissions via RBAC: `get_access(identifier)`
- Use `authorize!` in controllers or `allowed_to?` in views
- Test with ActionPolicy RSpec matchers

### AnyCable WebSockets
- AnyCable replaces default Action Cable for better performance
- Redis backend required
- Configuration in `anycable.toml`
- WebSocket server runs separately in development and CI

## Common Gotchas

- Freezolite adds `frozen_string_literal: true` to all files automatically (disabled in test env)
- Components must be in `app/components/` and are autoloaded
- Adminit area requires accounts to have a role assigned
- Permission resources are identified by policy class identifiers (e.g., `:"Adminit::ApplicationPolicy"`)
- HABTM associations used for roles/permissions (not has_many :through)
