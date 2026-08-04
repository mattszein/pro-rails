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

## NEVER precompile assets in development or test

**Do not run `assets:precompile` (or `bin/rails assets:precompile`, `rake assets:precompile`) in dev
or test. Ever.** Precompiling is a production/deploy step only — the CI and deploy pipelines handle it.

Propshaft resolves assets dynamically from source in dev/test. The moment `public/assets/` contains a
precompiled build, Propshaft serves those fingerprinted files instead, and **every subsequent edit to
JS, CSS or Stimulus controllers is silently ignored in the browser.** Nothing errors. The app just
keeps serving the stale build, so you debug code that isn't running — chasing "impossible" behaviour
and writing fixes for bugs that no longer exist in the source.

Symptoms that mean you (or a previous session) precompiled:

- A JS/CSS/Stimulus change has no effect in the browser, but the source is definitely correct.
- A bug you already fixed keeps reappearing, or behaves differently on each page load.
- Stimulus controllers appear to initialize twice (stale + fresh copies both registered).
- `public/assets/` exists and is non-empty — in a healthy dev checkout it should not be.

Recovery — delete the precompiled output and let Propshaft go back to serving from source:

```bash
docker compose exec rails bin/rails assets:clobber   # or: rm -rf public/assets
```

`/public/assets` is gitignored, so this never shows up in `git status` — which is exactly why it
wastes so much time. If frontend behaviour looks impossible, check for it *first*, before debugging
the code.

## Skills

When you detect any of these contexts, IMMEDIATELY read the corresponding skill file BEFORE writing any code. Multiple skills can apply simultaneously.

| Context | Skill |
| ------- | ----- |
| Planning features, scoping ideas, product tradeoffs | `docs/PROJECT.md` |
| Architecture decisions, pattern selection, file structure | `docs/ARCHITECTURE.md` |
| Models, controllers, interactors, jobs, services, migrations, I18n | `docs/BACKEND.md` |
| Views, components, Stimulus, Turbo, CSS, JS | `docs/FRONTEND.md` |
| Writing tests, specs, factories, fixing test failures | `docs/TESTER.md` |
