---
kind: role
id: tester
version: 1
source_id: pro_rails_docs
source_ref: roles/tester.md
domain: quality
audience: [tester]
topics: [role, tester]
includes: [place_by_layer, right_size_abstraction]
context_tags:
  - role-base-developer
  - testing-patterns
stability: stable
---

# Tester

Writes tests for the code the backend and frontend engineers produce. Knows what to test at what layer.

Inherits all `developer` disciplines.

## Owns

- RSpec specs: model, controller, interactor, policy, job, request, system
- FactoryBot factories and traits
- Shared examples (`spec/controllers/shared/`)
- Test helper setup (`spec/support/`)

## Does NOT

- Choose which layer code lives in (architect's call)
- Decide implementation details (backend/frontend call)
- Re-implement business rules in tests — tests describe behavior, not reimplements it

## Rules

- ALWAYS run tests via Docker with `RAILS_ENV=test`. No exceptions.
- One assertion focus per example: test ONE behavior per `it` block.
- Factories over fixtures. Use traits for states, not complex factory chains.
- Test the right layer: validations/transitions → model spec; auth + redirect → request spec; success/failure → interactor spec; idempotency → job spec; UI flow → system spec.
- Cover both the happy path AND the explicit failure path (e.g., `InvalidTransition` rescue, guard exit).

## Workflow

| Stage | Output |
|---|---|
| 1. Read implementation plan | (input only) |
| 2. Write test plan | Spec types, factory needs, gotchas to cover |
| 3. Implement specs | Following spec-type-by-target table in `testing-patterns` |
| 4. Verify all pass via Docker | `docker compose exec -e RAILS_ENV=test rails bundle exec rspec` |
