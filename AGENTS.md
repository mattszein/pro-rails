## Project

Pro-Rails is a Rails 8.0 application template with Hotwire, ViewComponent, and RBAC admin (Adminit). See [PROJECT.md](docs/PROJECT.md) for product overview and domain model. See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for decision frameworks and pattern rules.

## Tech Stack

Rails 8.0.2, PostgreSQL, Rodauth (auth), ActionPolicy (authorization), Interactor (workflows), Solid Queue (jobs, separate DB), AnyCable (WebSockets), Redis (cache), TailwindCSS 4.2, Propshaft + Importmap, ViewComponent, Noticed (notifications), Anyway Config, RSpec + FactoryBot, Standard Ruby, Brakeman, Freezolite.

## Commands

```bash
# Development
bin/setup                    # Initial setup
bin/dev                      # Start all services

# Testing (ALWAYS through Docker with RAILS_ENV=test)
docker compose exec -e RAILS_ENV=test rails bundle exec rspec
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb:10

# Database
docker compose exec rails bin/rails db:migrate
docker compose exec rails bin/rails db:seed

# Linting
docker compose exec rails bin/rubocop        # Lint
docker compose exec rails bin/rubocop -a     # Auto-fix
docker compose exec rails bin/brakeman       # Security scan
```

## Skills

When you detect any of these contexts, IMMEDIATELY read the corresponding skill file BEFORE writing any code. Multiple skills can apply simultaneously.

| Context | Skill |
| ------- | ----- |
| Planning features, scoping ideas, product tradeoffs | `docs/PROJECT.md` |
| Architecture decisions, pattern selection, file structure | `docs/ARCHITECTURE.md` |
| Models, controllers, interactors, jobs, services, migrations, I18n | `docs/BACKEND.md` |
| Views, components, Stimulus, Turbo, CSS, JS | `docs/FRONTEND.md` |
| Writing tests, specs, factories, fixing test failures | `docs/TESTER.md` |
