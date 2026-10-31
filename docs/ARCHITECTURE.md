# Architecture Reference

Rules and boundaries. Code examples live in the skills (backend, frontend, tester). Product overview: [PROJECT.md](PROJECT.md).

## Core Principles

1. **Right tool for the complexity**: simple solutions for simple problems, patterns for complex ones. Escalate on evidence, not in advance.
2. **Single source of truth**: each rule lives in one place.
3. **Explicit over implicit**: visible dependencies, no hidden magic.
4. **Defense in depth**: several layers protect data integrity.
5. **Consistency boundaries over model count**: an operation owns every write that keeps its aggregate consistent; anything that crosses that boundary is orchestrated elsewhere.

---

## Layers

| Layer | Owns | Answers |
|---|---|---|
| Model | Integrity, transitions, owned records | Is this valid? Is this transition legal? |
| Controller | HTTP, authorization, UX guards | Can this user attempt this? |
| Interactor | Workflows beyond one aggregate, side effects | What must happen, in what order? |

```
Controller (params, authorize!)
  → CRUD                           → Model
  → single-aggregate transition    → model.transition!
  → anything beyond the aggregate  → Interactor → transition + jobs / notifications
```

### Where Code Belongs

| Code | Home |
|---|---|
| Validations, cross-attribute invariants | Model |
| Transitions + their owned records (history notes) | Model transition method |
| UI state queries | Model query methods |
| Reusable or table SQL | Model scope / class method |
| Record-state broadcasts | Model |
| Destroy protection | Model `before_destroy` |
| Who may act | Policy (ActionPolicy) |
| HTTP, UX guards, row-level access | Controller |
| Domain error → HTTP response | `TransitionErrors` concern |
| Table sort/filter whitelist | `Core::Table::Column` / `Filter` (per context) |
| Side effects, cross-aggregate writes, workflow notes and broadcasts | Interactor |
| 4+ reusable steps | `Interactor::Organizer` |
| Notifications | Noticed notifier, triggered by an interactor |
| Background work | Solid Queue job |
| External APIs | Service object |
| Multi-step content processing | Pipeline (`app/services/`) |
| Typed configuration | Anyway Config |
| Bidirectional real-time | ActionCable channel, one per concern |
| DOM behavior / complex JS logic | Stimulus controller / `app/javascript/models/` |

There is no `app/queries/`. A query with no owning model that is reused across domains goes in `app/services/` as a reporting object (not needed yet).

### Domain Errors in Controllers

The `TransitionErrors` concern rescues `DomainError` and `RecordInvalid` raised by transitions. Interactor failures render through the same method, so both paths look identical to the user. Never rescue `InvalidTransition` ad hoc.

---

## Authentication

Rodauth (`app/misc/rodauth_main.rb`, `app/misc/rodauth_app.rb`). Account status: `unverified` 1, `verified` 2, `closed` 3. Current user: `current_account`. No `CurrentAttributes`: request context is passed explicitly.

## Authorization

ActionPolicy with custom RBAC in Adminit. Three gates: `Account#adminit_access?` → `before_action :authorize_adminit_access` → `authorize!` per action.

Each policy defines `POLICY_RESOURCE` (an integer enum key in `Permission::RESOURCE_REGISTRY`) and `self.identifier`. The base `get_access` calls `Role#permitted?`, which checks a memoized `Set`, so there is one query per request however many checks run.

Policy answers "can this USER?"; the model answers "can this RECORD?".

New resource: add the registry key (never reuse an integer) → policy with `POLICY_RESOURCE` → `self.identifier`.

---

## Model Rules

### Aggregates

An aggregate is a root plus the records it owns. A record is owned if it has no meaning without the parent, is destroyed with it, and is never written independently. A ticket's system notes are owned; `Account` is not.

### Validations

The last line of defense: they fire for every caller. Use `status_was` for the previous value. Cross-attribute invariants are validations, not corrective callbacks: a wrong path fails loudly instead of being silently fixed.

### Transition Methods

The only path that changes state columns and ownership FKs (`status`, `ai_state`, `assigned_id`). Controllers never mass-assign them.

- Every guard runs inside `with_lock`, which reloads the row. Use plain `with_lock`, no helper.
- One `update!` per transition. Never compose bang transitions.
- May write owned records inside the lock.
- No side effects: no jobs, mail, notifications or external I/O, so models stay safe in the console, tests and seeds. Record-state `after_commit` broadcasts are fine.
- Returns `self`.
- Every transition has a stale-instance spec. That spec is what enforces the lock rule.

### Callbacks

| Score | Type | Example | Action |
|---|---|---|---|
| 5 | Transformer | `before_validation :normalize_email` | Keep |
| 4 | Normalizer / counter | `before_save :strip_whitespace` | Keep |
| 3 | State broadcast | `broadcasts_to` | Keep |
| 2 | Domain mutation | `before_save :release_ai_on_assignment` | Explicit transition step + invariant validation |
| 2 | Observer | `after_save :notify_admin` | Move to an interactor |
| 1 | Operation | `after_create :send_welcome_email` | Move to an interactor |

Keep a callback if removing it breaks integrity. Callers never pre-capture state, or read `saved_change_to_*`, to learn what a callback did; the transition makes it explicit.

### Other Model Rules

- **Exceptions:** `DomainError` → `Model::InvalidTransition` → subclasses that callers must distinguish (`AlreadyAssigned`).
- **Destroy protection:** `before_destroy` with `throw(:abort)`.
- **Audit records (system notes):** immutable. Use `before_update` → abort, and `before_destroy` → abort unless `destroyed_by_association`. Not `readonly?`, which also blocks the parent's `dependent: :destroy`. Policies expose no edit or delete. Notes describing the transition are written by the model; notes carrying workflow context by the interactor. English only.
- **Concerns:** cross-model → flat in `app/models/concerns/`; model-specific → `concerns/{model}/`, starting with the model's 2nd concern.
- **Namespaces:** related models forming a domain → namespace (`Support::Ticket`, `Support::Conversation`). Standalone or cross-domain models → none.
- **STI vs enum:** STI when subtypes differ in behavior or type conditionals appear in 3+ places; enum when variants differ only in label.

---

## Table Queries

- SQL (filters, search) is a model scope or class method. A model with 2+ query clusters → a model concern.
- The sort/filter whitelist is declared once, on the column set (`Core::Table::Column#sort_key` / `#filter`, `app/components/core/table/column.rb`). The controller passes the same array to `Tableable#apply_table_params` (`app/controllers/concerns/tableable.rb`) and to the view, so they can't drift, and a request can't touch a field the table doesn't render.
- Capability is per context, not per model: `/support/tickets` and `/adminit/tickets` have different column sets and row scopes on purpose. One whitelist keyed off the model couldn't express that.
- Row-level access is the controller's base relation, set before filters. Filters `AND` onto it, so they only narrow and can never escape a scope like `where(created_id: current_account.id)`.
- Association option lists go through a scope named for their audience (`Role.selectable`, `Account.assignable`), never a raw `where` in the helper: rendering a list discloses its contents.
- Role-conditional columns use `allowed_to?` in the column helper, which removes header, cell, sort link and filter together. Not built yet: `Permission::RESOURCE_REGISTRY` is resource-level only, so per-field capability isn't expressible until a real need appears.

Where a query goes:

| Situation | Home |
|---|---|
| One-off, single action | `where` in the controller |
| Reused or non-trivial | Model scope |
| Returns an aggregate or hash | Model class method (`dashboard_stats`) |
| 2+ query clusters | Model concern (`Support::Ticket::Filterable`, `Account::Statistics`) |
| Needs request state | Controller lambda over a scope |
| No owning model, cross-domain | Reporting object in `app/services/` |

---

## Interactor Rules

- An interactor exists only when the operation goes beyond one aggregate: side effects, cross-aggregate writes, or request context. Introduce it with the first side effect.
- Rescue only `DomainError` and `RecordInvalid`. Bugs bubble up.
- Transactions only for writes across aggregates in the same DB. A single aggregate is covered by the transition's lock.
- Solid Queue is a separate DB: enqueue jobs and deliver notifications after the transition returns, never inside a transaction (the job could run before the commit).
- Organizer for 4+ reusable steps.
- Pass request context (IP, user-agent) explicitly.

## Background Jobs

- Idempotent. Guards: the record exists and its timestamp matches.
- No correctness guards: locked transitions raise `InvalidTransition`, even when the job holds a stale record. A cheap early return is allowed only to skip expensive work (an LLM call); the locked step re-checks.
- Critical jobs get a recurring safety net.
- A failed enqueue is logged and doesn't undo the state change before it.

## Pagination

| Case | Use |
|---|---|
| Admin tables (< 100K rows) | `pagy` / `pagy_countless` |
| Infinite scroll | `pagy_countless` + Turbo Frames |
| Chat, messages, audit logs (10K+, live inserts) | Cursor (`WHERE id < :cursor`): O(1), unlike OFFSET |
| API | `pagy` + `pagy/extras/headers` |

## Real-Time

- A broadcast that reflects record state lives in the model (`broadcasts_to` / `after_commit`), even when conditional: it must fire on every path.
- A broadcast that exists because of one workflow lives in that interactor. User-specific broadcasts: interactor or controller.
- Broadcast partials have no `current_account`: their HTML is viewer-neutral. Per-viewer visibility is decided client-side (`<turbo-show>`); authorization stays in the policy, so a hidden or stale control still can't act.
- A broadcast that replaces an input area (composer) fires only when its variant changes, never on every update, or it wipes what the user is typing.
- One channel per concern. Turbo Streams for server-to-client HTML; a custom ActionCable channel for bidirectional features (typing, presence).

## Notifications

Triggered from interactors only, outside transactions. Many recipients → an idempotent job that skips those already notified.

---

## Feature Flags

- `DeclaredRegistry` (`app/lib/declared_registry.rb`) gives code-declared sets (`FeatureFlags::Registry`, `AudienceConditions::Registry`, `Dashboard::WidgetRegistry`) a shared store and reload (`all`, `keys`, `registered?`, `reset!`). `register` and readers stay per registry because guards and naming differ (`Dashboard::WidgetRegistry#register` enforces duplicate-key and span rules; its reader is `find`, not `fetch`). Declarations autoload, so edits hot-reload in dev; an initializer re-runs `install` on `to_prepare`.
- The decision (`FeatureFlags`, `AccountEvaluator`) queries models, so it lives in `app/models/`. Registries and declarations stay in `app/lib/`.
- One entry point: `FeatureFlags.for(account)` / `.enabled?(key, account)`. Nothing else, admin code included, reads `feature_flag_accounts` / `feature_flag_audiences` to decide; admin reads them only to display.
- Never call it from models, migrations, or job/broadcast paths that write: they have no request account.
- The evaluator is request-scoped, never cached process-wide.
- No write may depend on a flag answer: withdrawing a flag must only change the read path, or the off path inherits records it can't interpret.
- Gate server-side. A CSS-hidden toggle still ships the capability.
- Flags have no attribution column; that history belongs to an audit log.

## I18n

- Files: 2+ domains → `{locale}/shared.yml`; one domain → `{locale}/{domain}.yml`; model layer (enums, validations, transition errors) → root `{locale}.yml`.
- Explicit keys (`t("adminit.tickets.updated")`), never lazy lookup.
- Enums: `t("enums.ticket.status.#{status}")`, never `.humanize`.
- Form labels always explicit.
- System notes in English; Turbo broadcasts locale-neutral.
- Every key in both `en` and `es`.

## ViewComponents

In `app/components/core/`. No queries: data comes from scopes. Feature-flag decisions arrive as constructor arguments; components never call `FeatureGated` / `FeatureFlags`. `CustomFormBuilder` is the default. Lookbook at `/lookbook`.

## JavaScript

`controllers/` thin Stimulus controllers · `models/` plain classes (extract past ~80 lines of non-DOM logic) · `icons/` SVG animations (`start` / `stop`) · `library/` shared utilities.

## File Organization

| Code | Location |
|---|---|
| Models, `domain_error.rb` | `app/models/` (namespaced subdirs) |
| Model concerns | `app/models/concerns/` (model-specific subdirs) |
| Controllers / concerns (`TransitionErrors`, `Tableable`) | `app/controllers/` / `app/controllers/concerns/` |
| Interactors | `app/interactors/{domain}/` |
| Policies | `app/policies/` (mirrors controllers) |
| Jobs / notifiers | `app/jobs/` / `app/notifiers/` |
| Services / pipelines | `app/services/external_services/` / `app/services/` |
| Components | `app/components/core/` |
| Config | `config/configs/` |
| JS | `app/javascript/{controllers,models,icons,library}/` |
| Locales | `config/locales/{en,es}/{domain}.yml` |
