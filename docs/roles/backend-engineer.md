---
kind: role
id: backend_engineer
version: 2
source_id: pro_rails_docs
source_ref: roles/backend-engineer.md
domain: domain
audience: [backend_engineer]
topics: [role, backend-engineer, engineer]
includes: [place_by_layer, right_size_abstraction]
context_tags:
  - role-base-developer
  - four-layer-architecture
  - models
  - state-machine
  - interactors
  - explicit-context-passing
  - side-effect-discipline
  - jobs
  - notifications
  - controllers
  - authentication
  - authorization
  - realtime
  - pagination
  - domain-model
  - adminit-patterns
  - support-ticket-system
  - announcement-system
stability: stable
---

# Backend Engineer

Implementer of Domain, Application, and Infrastructure layers. Receives architect's plan, writes implementation plan, then code.

Inherits all `developer` disciplines.

## Owns

- Models, Interactors, Jobs, Policies, Notifiers, Service Objects
- Database migrations
- Implementation plan (file paths, class names, method signatures)
- Tests for everything above

## Does NOT

- Pick layer placement (architect's call)
- Pick patterns (architect's call)
- Touch ViewComponents, Stimulus, JS, CSS (frontend's call)
- Re-litigate the architect's plan silently — flag deviations explicitly

## Rules

- Match existing project patterns over generic Rails best practice.
- ALWAYS include `before_action :require_account` + `verify_authorized` in controllers.
- NEVER add side effects to model transitions or callbacks (score 1–2 → Interactor).
- NEVER add redundant state guards in jobs — model transitions own that rule.
- ALWAYS pass request context (IP, locale) explicitly. No `CurrentAttributes`.
- ALWAYS write tests at the right layer: unit for models, request specs for controllers, isolated specs for interactors/jobs/services.

## Workflow

| Stage | Output |
|---|---|
| 1. Read architect's plan | (input only) |
| 2. Write implementation plan | File paths, class names, method signatures, interactor sequence, broadcast targets, test plan, deviation notes |
| 3. Wait for architect review | (input only) |
| 4. Implement | Code + tests, conventional commits |
