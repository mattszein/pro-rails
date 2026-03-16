# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For detailed architecture patterns, design decisions, and conventions see [ARCHITECTURE.md](ARCHITECTURE.md). It covers: request flow, when to use controllers vs interactors, model patterns (validations, state transitions, destroy protection), authorization layers, ViewComponent/form builder, broadcasting patterns, background jobs, notifications, and testing patterns.

## Project Overview

Pro-Rails is a Rails 8.0 application using modern Rails stack with Hotwire (Turbo/Stimulus), ViewComponent architecture, and a role-based access control (RBAC) admin system called "Adminit".

## Tech Stack

- **Rails**: 8.0.2 with PostgreSQL
- **Frontend**: Hotwire (Turbo, Stimulus), TailwindCSS 4.2, Propshaft (asset pipeline)
- **Authentication**: Rodauth with multi-phase login and email auth
- **Authorization**: ActionPolicy with custom RBAC system
- **Components**: ViewComponent with custom form builder
- **WebSockets**: AnyCable for Action Cable
- **Cache**: Redis
- **Background Jobs**: Solid Queue (PostgreSQL-backed)
- **Notifications**: Noticed gem
- **Workflows**: Interactor gem
- **Testing**: RSpec with FactoryBot, Shoulda-Matchers, Capybara + Cuprite for system tests
- **Code Quality**: Standard Ruby linter, Brakeman for security scanning
- **Code Conventions**: Freezolite auto-adds frozen_string_literals (disabled in test environment)
- **I18n**: rails-i18n gem for built-in locale data, URL-based locale switching (`/:locale/` prefix)

## Development Commands

### Setup

DOCKER: We use docker and docker-compose for local development. Execute any
command using docker compose! rails backend service is called rails.
Always pass `RAILS_ENV=test` when running rspec, e.g.:
`docker compose exec -e RAILS_ENV=test rails bundle exec rspec`

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

Lookbook is available in development at `/lookbook` for component previews. Components are in `app/components/core/`.

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

## I18n Conventions

- **Available locales**: English (`:en`, default) and Spanish (`:es`)
- **Locale switching**: URL-based with optional `/:locale/` prefix (e.g., `/es/dashboard`). English has no prefix.
- **Locale files**: Split by domain under `config/locales/{locale}/` subdirectories (`shared.yml`, `adminit.yml`, `support.yml`, `settings.yml`, `rodauth.yml`, `mailers.yml`)
- **Locale file organization**: Domain-based — all text about a domain goes in that domain's file. Cross-domain shared text (labels, buttons, navigation, layout) goes in `shared.yml`. Decision rule: used by 2+ domains → `shared.yml`; specific to one domain → that domain's file; model-layer (enums, validations) → root `en.yml`/`es.yml`
- **Translation key convention**: Explicit namespaced keys (e.g., `t("adminit.tickets.updated")`, `t("shared.labels.title")`), not lazy lookup
- **Enum display values**: Use `t("enums.ticket.status.#{status}")` instead of `.humanize`
- **Form labels**: Always pass explicit `label: t(...)` to form fields — don't rely on `.humanize` auto-generation
- **System notes in interactors**: Keep in English — they are internal audit records stored in the DB
- **Turbo broadcasts**: Keep locale-neutral — they render data, not translated labels
- **Locale concern**: `Localizable` concern (included in both `ApplicationController` and `Adminit::ApplicationController`) handles `around_action :switch_locale` and `default_url_options` with locale
- **Fallbacks**: Enabled globally — missing Spanish keys fall back to English
- **Adding new strings**: Always add to both `en/` and `es/` locale files. Never hardcode user-facing strings in views, controllers, or components

## Common Gotchas

- Freezolite adds `frozen_string_literal: true` to all files automatically (disabled in test env)
- Components must be in `app/components/` and are autoloaded
- Adminit area requires accounts to have a role assigned (three-layer authorization)
- Permission `resource` column is an integer enum (`Permission::RESOURCE_REGISTRY`). Never reuse integer values when removing a resource
- Policies must define `POLICY_RESOURCE` (matching an enum key, e.g., `:account`) and `self.identifier` (for ActionPolicy)
- When adding a new Adminit policy, add the resource to `Permission::RESOURCE_REGISTRY` and set `POLICY_RESOURCE` on the policy
- HABTM associations used for roles/permissions (not has_many :through)
- Support models are namespaced under `Support::` (Ticket, Conversation, Message)
- Account model has two ticket associations: as creator (`:created_id`) and assignee (`:assigned_id`)
- CustomFormBuilder is set as `default_form_builder` in `ApplicationController` — no need to pass `builder:` explicitly
- Turbo broadcasts use AnyCable secret for signed stream verification
- `dom_id` is NOT available in model context — use `ActionView::RecordIdentifier.dom_id(record, "prefix")`
- Use `:unprocessable_content` not `:unprocessable_entity` (Rack deprecation)
- Routes are wrapped in `scope "(:locale)", locale: /en|es/` — all route helpers automatically include locale via `default_url_options`. Health check, MissionControl, and Lookbook remain outside the scope
- `default_url_options` sets `locale: nil` for English (omits prefix) and `locale: :es` for Spanish — this prevents positional route args (like model records) from being misinterpreted as the locale param

## Controller Testing Gotchas

- Rodauth rack middleware does NOT run in controller tests. Without `before_action :require_account`, `current_account` is nil → NoMethodError.
- `verify_authorized` after_action fires even when Rodauth redirects at rack level, causing `AuthorizationContextMissing`. Fix: add `before_action :require_account` to halt the chain.
- `ensure_frame_response` before_action redirects before the action body runs. Test turbo frame actions with `@request.headers["Turbo-Frame"] = "modal"` (not the `headers:` kwarg — controller tests don't support it).
- ActionPolicy `be_authorized_to` matcher: use `a_kind_of(Class)` for STI subclasses or records built during the action; use the exact record for pre-existing records.
- Every user-facing controller accessing `current_account` must have `before_action :require_account` + `verify_authorized` + `authorize!` calls.
