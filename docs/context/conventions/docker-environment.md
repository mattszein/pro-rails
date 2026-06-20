---
kind: context
id: docker_environment
version: 1
source_id: pro_rails_docs
source_ref: context/conventions/docker-environment.md
domain: tooling
audience: [developer, architect, backend_engineer, frontend_engineer, tester]
topics: [role-base-developer, docker, environment, tooling]
references: []
stability: stable
---

# Docker Environment (Pro-Rails)

Container name: `rails`. Everything app-side runs through it. Git stays on host.

## Commands

```bash
# Setup (host)
bin/setup
bin/dev                                # Starts all services

# Tests — RAILS_ENV=test is MANDATORY
docker compose exec -e RAILS_ENV=test rails bundle exec rspec
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb:10

# Database
docker compose exec rails bin/rails db:migrate
docker compose exec rails bin/rails db:seed
docker compose exec rails bin/rails db:rollback

# Console
docker compose exec rails bin/rails console
docker compose exec -e RAILS_ENV=test rails bin/rails console

# Lint & security
docker compose exec rails bin/rubocop          # Standard Ruby
docker compose exec rails bin/rubocop -a       # Auto-fix
docker compose exec rails bin/brakeman         # Security
docker compose exec rails bin/erb_lint --lint-all
```

## Rules

| Rule | Why |
|---|---|
| ALWAYS pass `-e RAILS_ENV=test` for any test command | Bare exec defaults to development env. Tests fail silently against wrong DB. |
| Git on HOST, never inside Docker | Container has no git config / SSH keys |
| Use `bin/dev` not `rails s` directly | Starts AnyCable, Solid Queue, asset watchers — not just web |

## Trap

`docker compose exec rails bundle exec rspec` (no `-e`) → runs against development DB. The dev DB has different data, the schema may diverge, tests pass or fail for the wrong reasons. Always include `-e RAILS_ENV=test`.
