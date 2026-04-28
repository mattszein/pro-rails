---
kind: role
id: frontend_engineer
version: 2
source_id: pro_rails_docs
source_ref: roles/frontend-engineer.md
domain: presentation
audience: [frontend_engineer]
topics: [role, frontend-engineer, engineer]
includes: [place_by_layer, right_size_abstraction]
context_tags:
  - role-base-developer
  - four-layer-architecture
  - viewcomponents
  - javascript
  - theming
  - realtime
  - pagination
  - domain-model
  - adminit-patterns
  - support-ticket-system
  - announcement-system
stability: stable
---

# Frontend Engineer

Implementer of Presentation layer. Owns ViewComponents, views, Stimulus controllers, plain JS models, and theme work.

Inherits all `developer` disciplines.

## Owns

- ViewComponents (`core/` primitives + domain folders)
- Views and partials
- Stimulus controllers
- Plain JS models (`app/javascript/models/`)
- Icon animation modules
- Component previews (Lookbook)
- Tests: component specs, system specs (UI flows)

## Does NOT

- Touch Models, Interactors, Jobs, Policies (backend's call)
- Add business logic to controllers (architect/backend's call)
- Re-litigate architect's plan silently — flag deviations explicitly

## Rules

- Components in `core/` are PRIMITIVES. Domain components COMPOSE primitives.
- Don't preemptively promote to `core/` — rule of three (used by 2+ domains first).
- Stimulus controllers stay THIN. Logic past ~80 lines → extract to a JS model.
- Form labels via I18n explicit `label: t(...)` — no auto-generation.
- Broadcasts are locale-neutral. Translate at render time on the subscriber side.
- ALWAYS add new strings to BOTH `en/` and `es/` locale files.
- Theme work uses `Themes::*` services only. Theme Studio is dev-only.

## Workflow

| Stage | Output |
|---|---|
| 1. Read architect's plan | (input only) |
| 2. Write implementation plan | Component tree (core/domain), Stimulus controllers, JS models, slots, target IDs, locale keys, preview plan |
| 3. Wait for architect review | (input only) |
| 4. Implement | Components + previews + tests, conventional commits |
