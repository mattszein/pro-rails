---
kind: context
id: viewcomponent_rules
version: 2
source_id: pro_rails_docs
source_ref: context/ui/viewcomponent-rules.md
domain: presentation
audience: [frontend_engineer]
topics: [viewcomponents, components, presentation, ui]
references: [javascript_architecture, i18n_conventions]
stability: stable
---

# ViewComponent Rules (Pro-Rails)

ViewComponent 4. Components live in `app/components/`.

## Structure

| Folder | Contains |
|---|---|
| `app/components/core/` | Reusable primitives (buttons, inputs, modals, alerts) |
| `app/components/{domain}/` | Domain-specific composed components (e.g. `adminit/`, `support/`, `notifications/`, `settings/`, `landing/`) |

Domain components COMPOSE core primitives to build feature UI.

## Promotion rule

A component starts in its domain folder. When a SECOND domain needs it → promote to `core/`. Don't promote preemptively (rule of three).

## Forms

`CustomFormBuilder` is the default form builder, set in `ApplicationController`. Forms don't need `builder:` kwarg — they get it automatically.

## Previews (Lookbook)

Component previews live in `test/components/previews/`. Available at `/lookbook` in development. Every non-trivial component should have a preview.

## Colocated controllers

When a Stimulus controller is tightly coupled to ONE component, place it alongside the component:

```
app/components/core/
  toast_component.rb
  toast_component.html.erb
  toast_component_controller.js   ← colocated
```

Use this only when the controller has no reuse outside the component. Otherwise it goes in `app/javascript/controllers/`.

## Rules

| Rule | Why |
|---|---|
| Core = primitive, domain = composed | Keeps `core/` reusable and stable |
| Don't preemptively promote to `core/` | Rule of three. First usage stays in its domain. |
| One component, one responsibility | Composition over options-explosion |
| Form labels via I18n explicit `label: t(...)` | No auto-generation from attribute names — see `i18n-conventions` |

## Layouts and Turbo

Layout chain: `application` layout wraps `dashboard` layout (sidebar, nav) wraps `adminit` layout (admin chrome). Never bypass the chain — each adds its own channel subscriptions and JS.

Modal pattern: `turbo_frame_tag "modal"` in the root layout catches any response that renders `turbo_frame_tag "modal"` — inline modals without a separate channel.

Lazy frames: `loading: :lazy` defers frame content until visible. Use for sidebar widgets and secondary panels that aren't needed on first paint.

Custom Turbo Stream action: `Turbo.StreamActions.redirect` ships with the project — performs a client-side redirect in response to a Turbo Stream. Used when an action changes the current page's identity (e.g., closing a ticket takes the admin away from the show page).
