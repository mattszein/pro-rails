---
kind: context
id: javascript_architecture
version: 2
source_id: pro_rails_docs
source_ref: context/ui/javascript-architecture.md
domain: presentation
audience: [frontend_engineer]
topics: [javascript, stimulus, frontend, hotwire]
references: [viewcomponent_rules]
stability: stable
---

# JavaScript Architecture (Pro-Rails)

Hotwire (Turbo + Stimulus). Plain JS for testable logic. No frontend framework.

## Where JS lives

| Location | Purpose |
|---|---|
| `app/javascript/controllers/` | Stimulus controllers — thin, orchestrate DOM |
| `app/javascript/models/` | Plain JS classes — complex logic, testable in isolation without a DOM |
| `app/javascript/icons/` | SVG animation modules (`start(svg)` / `stop(svg)` exports) — one module per animated icon |
| `app/javascript/library/` | Shared utilities and custom elements (e.g. `turbo_show.js` — a `<turbo-show>` custom element for conditional visibility) |

## Extraction rule

When a Stimulus controller grows past ~80 lines of NON-DOM logic → extract the logic to `models/`. The controller keeps event handling and target orchestration; the model is plain JS, unit-testable without a DOM.

```
controller.js (thin)         model.js (testable)
├── connect()                ├── class TicketState {
├── targets/values             ├── transition(event) { ... }
├── action handlers ──calls──▶ ├── computeNext() { ... }
└── DOM updates              └── isValid() { ... }
                             }
```

## Colocated controllers

When a Stimulus controller is tied to ONE component, place it next to the component file (e.g. `core/toast_component_controller.js` next to `core/toast_component.rb`). Otherwise it goes in `app/javascript/controllers/`.

See `viewcomponent-rules` for component-side rules.

## Rules

| Rule | Why |
|---|---|
| Controllers = thin DOM orchestration | Reusable, simple to read |
| Models = framework-free, testable | No `this.element`, no Stimulus targets — pure JS |
| Icons get a module per icon, not inline SVG strings | Animatable, swappable, testable |
| Custom elements (`turbo_show.js` etc.) live in `library/` | Cross-cutting reuse |
