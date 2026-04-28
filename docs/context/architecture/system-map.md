---
kind: context
id: system_map
version: 1
source_id: pro_rails_docs
source_ref: context/architecture/system-map.md
domain: architecture
audience: [architect]
topics: [architecture-overview, system-map, stack, patterns, decisions]
references: [four_layer_architecture]
stability: stable
---

# System Map (Pro-Rails)

Architect-level overview. For exact field rules and code shapes, consult the backend-engineer detail files.

## Stack at a glance

| Library | Role |
|---|---|
| Rails 8.0.2 | Web framework, ORM, routing, mailers, ActionText |
| Rodauth | Authentication (Rack middleware, no monkey-patching) |
| ActionPolicy | Authorization (policy objects + DB-backed RBAC) |
| Interactor gem | Application-layer workflow boundary |
| Solid Queue | Background jobs (PostgreSQL-backed, SEPARATE database) |
| AnyCable | WebSocket server (replaces ActionCable in production) |
| ViewComponent 4 | Encapsulated UI components with Lookbook previews |
| Anyway Config | Typed configuration classes with ENV override |
| Noticed | Multi-channel notification delivery |
| Pagy | Pagination (offset and cursor strategies) |
| TailwindCSS 4.2 | Utility-first CSS with `@theme` and OKLCH palettes |
| Propshaft + Importmap | Asset pipeline — no Node.js build step |
| RSpec + FactoryBot | Test framework (unit, integration, system) |
| Standard Ruby | Zero-config linter (`bin/rubocop`) |
| Brakeman | Static security analysis |
| Freezolite | Repo-wide frozen string literals (no per-file magic comment) |

## Layers

**Domain** anchors around ActiveRecord. Models own business rules, validations, state
transitions, scopes, query methods, and CRUD broadcasting via `broadcasts_to`. The
Domain layer is the last line of defense for data integrity — validations fire
regardless of caller (controller, interactor, job, console, seed). State machines are
hand-rolled: integer enum + transition method + `InvalidTransition` exception per arc.
No AASM or state_machines gem.

**Application** owns orchestration and side effects. Interactors answer "what sequence
must happen" — they call model transitions and then trigger jobs, emails, broadcasts,
and external services. Policies (ActionPolicy) answer "is this user allowed to do this."
Notifiers (Noticed) handle multi-channel delivery, always triggered from Interactors.
All side effects live in this layer. Request context (IP, locale, actor) travels through
this layer as explicit keyword arguments.

**Infrastructure** covers persistence, external integrations, and configuration. Solid
Queue handles background jobs in a SEPARATE PostgreSQL database — `perform_later` is
never part of the app's transaction. Service Objects wrap external API calls. Anyway
Config classes provide typed, ENV-overridable configuration. This layer MUST NOT contain
business rules.

**Presentation** handles HTTP and rendering. Controllers are thin: parse params,
authorize, call an Interactor or model, respond. ViewComponents provide encapsulated,
testable UI units. Stimulus controllers orchestrate DOM events and delegate complex
logic to plain JS models. AnyCable handles bidirectional WebSocket connections. Mailers
are triggered only by Application layer events.

## Patterns we use

**State machines (hand-rolled).** Each model with a lifecycle defines: (1) an integer
enum `status`; (2) one transition method per arc that raises `Model::InvalidTransition`
on bad state and calls `update!` on success; (3) query methods (`editable?`,
`destroyable?`, `messageable?`) that return booleans for UI guards. The Interactor calls
the transition and rescues `InvalidTransition`, forwarding the message via
`context.fail!`. No AASM — the pattern is simple enough to own directly.

**Explicit context passing.** Request context (IP address, locale, acting account)
travels as keyword arguments from controller → interactor → job/service. `CurrentAttributes`
is forbidden. No thread-locals. Every caller is testable in isolation with any context.
The chain: controller reads `request.remote_ip` and `I18n.locale`, passes them to
`Interactor.call(ip_address:, locale:)`, which passes primitives to jobs.

**Side-effect discipline.** Models hold data integrity only. Jobs, emails, API calls, and
conditional broadcasts live exclusively in Interactors. Callbacks are scored 1–5: scores
4–5 (transformers, normalizers, counters) stay in models; scores 1–2 extract to
Interactors. `broadcasts_to` is score 3 and is the one CRUD-sync exception that stays in
models. Test: if removing a callback breaks data integrity → keep; if it triggers
external work → extract.

**Three-layer auth (Adminit).** Account-level gate (`Account#adminit_access?`, checked
via `authorize_adminit_access`) → controller-level gate (inherited from
`Adminit::ApplicationController`) → policy-level check (`verify_authorized` + `authorize!`
per action). Skip any layer and security silently degrades. Permissions are
runtime-manageable via the DB — no code deploy needed to change who can access what.

**CRUD broadcasting vs conditional via Interactor.** Simple CRUD sync uses `broadcasts_to`
in the model — fires synchronously on the same transaction, no request context needed.
Complex workflow broadcasts (a status change that fans out to multiple different targets
with different partials for different audiences) go in the Interactor using
`Turbo::StreamsChannel.broadcast_*` explicitly for each target. Never use a model
callback for conditional broadcasts.

**Locale-neutral broadcasts.** Partials rendered via Turbo Stream carry raw data, not
translated strings. Translation happens on the subscriber side at render time. Interactors
never embed locale-specific text in a broadcast payload. This is critical because admin and
user streams for the same ticket state change may be subscribed by users with different
locales — each must receive correctly translated output.

**Two-guard idempotency in jobs.** Every critical job accepts a primitive expected-state
value (e.g., `scheduled_at.to_i`) alongside the record ID. Guard 1 checks existence:
`return unless record = Model.find_by(id:)` — handles deleted records silently. Guard 2
checks expected state: `return if record.state_field != expected` — handles reschedules
and stale retries. Both guards must pass before the job does work. `find_by` not `find`
— a deleted record must be a silent no-op, not a retriable `RecordNotFound`.

**Custom FormBuilder.** `ApplicationController` sets `default_form_builder CustomFormBuilder`.
Every `form_with` call automatically uses component-backed inputs — consistent error
rendering, consistent label handling, no raw HTML inputs in views. Inherited by all
controllers; no per-form configuration needed.

## Features

**Adminit (RBAC admin panel).** Built without an admin gem — plain Rails controllers and
ViewComponents under the `Adminit::` namespace. Authorization is fully runtime-manageable:
roles, permissions, and role-permission mappings are stored in the DB.
`Permission::RESOURCE_REGISTRY` maps resource symbols to stable integer enum values —
integers are permanently assigned, never reused. The three-layer auth chain ensures
defense in depth. Adding a new admin resource requires: registry entry → policy →
controller guard → routes → I18n keys.

**Support tickets.** Full lifecycle system with real-time conversations. States:
`open → in_progress → finished → closed` plus a reopen sub-flow
(`finished → reopen_requested → reopened → in_progress` or `closed` if rejected). Seven
transitions total, each with a dedicated Interactor. The most complex broadcast pattern
in the app: a single state change fans out to five Turbo Stream targets (user list, admin
list, user show, admin show, admin notes). Two Account FKs (creator + assignee).
Conversation auto-created on ticket creation. Note kinds: `system` (audit trail by
interactors) and `internal` (admin-only visibility).

**Announcements.** Three-state lifecycle: `draft → scheduled → published`. Published
state is permanent — no revert. Scheduling enqueues a `PublishAnnouncementJob` with a
staleness guard: aborts if `scheduled_at.to_i` changed since enqueue (handles rescheduling
races). Publishing triggers a fan-out to all verified accounts via
`BulkAnnouncementNotificationJob`. ActionText for rich body; a `before_validation`
callback denormalizes into a plain `body` column for full-text search. Immutability
guards use `status_was` (not `status`) to distinguish in-progress transitions from
completed state checks.

**Notifications (Noticed).** Two-level UI: header bell (unread count + 10 most recent)
and full notifications page (paginated with infinite scroll, mark-read per notification
and mark-all-as-read). Delivery via `deliver_by :email` (AccountMailer) +
`deliver_by :custom` (TurboStream delivery method — pushes to the layout's notification
stream). Bulk delivery always enqueued as a fan-out job, never delivered inline.
One Notifier class per logical event.

**Theming.** 40 named themes across 5 categories (Tech Edge, Serene, Cosmic, Vivid,
Night Owl). Two-layer CSS architecture: `default.css` defines all semantic tokens;
per-theme files override only `primary-*` and `secondary-*` palette stops, leaving
all action/surface tokens from the default. OKLCH palette generation from `(hue, chroma)`
scalar inputs via `Themes::PaletteGenerator`. Theme Studio at `/dev/themes/studio` is
dev-only and namespace-isolated for potential future engine extraction
(`Themes::*`, `Dev::Themes::*`).

## Library choices and why

| Choice | Rationale |
|---|---|
| Rodauth over Devise | Rack middleware — no monkey-patching; feature-complete (verification, magic links, MFA-ready) without plugins |
| ActionPolicy + DB-backed RBAC | Runtime-manageable permissions without deploys; policy objects are plain Ruby; one DB query per request regardless of check count |
| Interactor gem | `context.fail!` replaces exception-driven control flow for expected domain failures; Organizer for 4+ reusable steps |
| Solid Queue (separate DB) | DB-backed jobs without Redis; separate DB forces explicit acknowledgment of the cross-transaction boundary |
| AnyCable over ActionCable | ~10× throughput; required for horizontal scaling; same API surface means no code changes |
| Hand-rolled state machines | 3 methods per arc; no DSL complexity, no version surprises, full debuggability |
| ViewComponent | Encapsulated, testable UI units; Lookbook for visual development; no admin DSL gem |
| Anyway Config | Typed config classes with IDE support; ENV override at runtime; readiness checks from initializers |
| Noticed | Clean `deliver_by` DSL; custom delivery methods for new channels are plain Ruby classes |

## Boundary conditions

- **Solid Queue separate database:** `perform_later` inside `transaction do` is NOT part of
  the app transaction. If the app TX rolls back, the job was already enqueued. Mitigation:
  safety-net recurring jobs for critical flows.
- **Locale-neutral broadcasts:** Never embed translated strings in a Turbo Stream broadcast.
  The subscriber translates at render time. Violating this causes wrong-locale text for
  subscribers with a different locale than the broadcaster.
- **`dom_id` not in model context:** Use `ActionView::RecordIdentifier.dom_id(record, "prefix")`
  explicitly. The `dom_id` helper is only available in views and controllers.
- **`CurrentAttributes` is forbidden:** Request context passes as explicit keyword arguments.
  No exceptions — thread-locals cause subtle failures in concurrent requests and job contexts.
- **`superadmin` role is reserved:** Do not delete or rename. It is the bypass grant for the
  permission management UI. If deleted, that UI loses its own access gate.
- **`Permission::RESOURCE_REGISTRY` integers are permanent:** Once assigned, an integer maps
  to one resource forever. Reuse silently reassigns all existing role-permission grants.

## When to consult detail files

This file is the architect's index. For exact field rules, code shapes, and non-obvious
constraints, the backend-engineer detail files are the source of truth:

| Need | File |
|---|---|
| Model validation, callback, concern, STI rules | `model-rules` |
| State machine shape, InvalidTransition, query methods | `state-machine-pattern` |
| Interactor structure, rescue rules, Organizer | `interactor-rules` |
| What belongs in models vs interactors | `side-effect-discipline` |
| Request context chain (IP, locale) | `explicit-context-passing` |
| Controller hierarchy, routing, error handling | `controller-patterns` |
| Policy architecture, RBAC, three-layer auth | `authorization-actionpolicy` |
| Adminit resource, permission registry, menu helper | `adminit-patterns` |
| Ticket lifecycle, transitions, multi-audience broadcasting | `support-ticket-system` |
| Announcement scheduling, staleness guard, fan-out | `announcement-system` |
| Job idempotency guards, separate DB boundary | `job-rules` |
| Pagy vs cursor pagination | `pagination-strategy` |
| CRUD broadcasts vs workflow broadcasts | `realtime-broadcasting` |
