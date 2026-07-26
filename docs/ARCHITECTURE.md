# Architecture Reference

Decision frameworks, pattern rules, and architectural boundaries. For implementation details and code examples, load the relevant skill (backend, frontend, tester). For product overview, see [PROJECT.md](PROJECT.md).

---

## Core Principles

1. **Right tool for the right complexity** — Simple solutions for simple problems, patterns for complex ones
2. **Single source of truth** — Each rule lives in one place
3. **Explicit over implicit** — Visible dependencies, no hidden magic
4. **Defense in depth** — Multiple layers protect data integrity

---

## Business Logic Layers

| Layer | Responsibility | Question It Answers |
|-------|----------------|---------------------|
| **Model** | Data integrity, state transitions | "Is this data valid?" / "Is this transition legal?" |
| **Controller** | HTTP handling, authorization, UX guards | "Can this user attempt this action?" |
| **Interactor** | Workflow orchestration, side effects | "What sequence of things must happen?" |

### Request Flow

```
HTTP Request
  → Controller (params, authorization via ActionPolicy)
    → Simple CRUD? → Model directly
    → Workflow?    → Interactor → Model + Jobs + Notifications
  → Model (validates, transitions, persists)
  → Controller (response: redirect, render, turbo stream)
```

### Pattern Selection

| Scenario | Pattern | Layer |
|----------|---------|-------|
| Simple CRUD (no side effects) | Controller + Model | Presentation + Domain |
| State change + side effects | Interactor | Application |
| Multiple models affected | Interactor | Application |
| External API call | Service Object | Infrastructure |
| Complex/reusable query | Model Scope or class method | Domain |
| Table sort/filter whitelist (what a request may touch) | `Core::Table::Column`/`Filter` on the controller's column set | Presentation |
| Authorization rules | Policy (ActionPolicy) | Application |
| Notifications | Notifier (Noticed) via Interactor | Application |
| Background processing | Job (Solid Queue) | Infrastructure |
| Real-time CRUD sync | `broadcasts_to` in Model | Domain |
| Bidirectional real-time | Custom ActionCable Channel | Presentation |
| Multi-step content processing | Pipeline (Chain of Responsibility) | Infrastructure |
| Typed configuration | Config class (Anyway Config) | Infrastructure |

**`app/queries/` is not part of this template.** A standalone query object is justified only when a
read has no owning model *and* is reused across domains — that case hasn't appeared. If it does, it
goes in `app/services/` as a reporting object, not a new top-level layer. See "Table Queries" below
for where table SQL and whitelists actually live.

---

## Authentication

Rodauth. Configured in `app/misc/rodauth_main.rb` and `app/misc/rodauth_app.rb`.

| Status | Value | Description |
|--------|-------|-------------|
| `unverified` | 1 | Account created, email not verified |
| `verified` | 2 | Email verified, active |
| `closed` | 3 | Closed by user or admin |

Access current user via `current_account` in controllers/views. No `CurrentAttributes` — request context is passed explicitly to interactors and services.

---

## Authorization

ActionPolicy with custom RBAC for admin (Adminit).

### Three-Layer Authorization (Adminit)

1. **Account-level gate** — `Account#adminit_access?` checks if role exists
2. **Controller-level gate** — `before_action :authorize_adminit_access`
3. **Policy-level check** — `authorize!` per action/resource

### Policy Architecture

Each policy defines `POLICY_RESOURCE` (matching an integer enum key in `Permission::RESOURCE_REGISTRY`) and `self.identifier`. The base `get_access` method checks whether the user's role has the matching permission via `Role#permitted?`, backed by a memoized `Set` of resource keys. One query per request regardless of how many policy checks run.

| Question | Where |
|----------|-------|
| "Can this USER do this?" | Policy |
| "Can this RECORD have this done?" | Model |

### Adding a New Adminit Resource

1. Add to `Permission::RESOURCE_REGISTRY` (integer enum — NEVER reuse values)
2. Create policy with `POLICY_RESOURCE` matching the enum key
3. Set `self.identifier` for ActionPolicy

---

## Model Rules

### Validations

Always in models. They're the last line of defense — fire regardless of caller (controller, interactor, job, console, seeds). Use `status_was` to check previous value in state-based validations.

### Transition Methods

Pure database operations. **NEVER** enqueue jobs, send emails, call APIs, or trigger any side effects from transition methods. This ensures models are safe to use in Console, Tests, and Seeds.

Side effects belong in the Interactor that calls the transition.

### Destroy Protection

Use `before_destroy` callbacks with `throw(:abort)` to prevent invalid deletions.

### Custom Exceptions

Define `InvalidTransition < StandardError` per model for domain-specific transition failures.

### Callback Scoring

| Score | Type | Example | Action |
|-------|------|---------|--------|
| 5 | Transformer | `before_validation :normalize_email` | Keep |
| 4 | Normalizer | `before_save :strip_whitespace` | Keep |
| 4 | Counter | `after_create :update_counter_cache` | Keep |
| 3 | Auto-broadcast | `broadcasts_to` (CRUD sync) | Keep |
| 2 | Observer | `after_save :notify_admin` | Extract to Interactor |
| 1 | Operation | `after_create :send_welcome_email` | Extract to Interactor |

**Rule**: If removing the callback breaks data integrity → keep. If it triggers external side-effects → extract.

### Concern Organization

Cross-cutting concerns (used by 2+ models) → flat in `app/models/concerns/`. Model-specific concerns → subdirectory named after the model, created when a model accumulates its 2nd concern.

### Namespace Decision

| Condition | Approach |
|-----------|----------|
| Multiple related models forming a domain | Namespace (`Support::Ticket`, `Support::Conversation`) |
| Single standalone model | No namespace (`Announcement`) |
| Model used across multiple domains | No namespace |

### STI vs Enums

| Use STI When | Use Enums When |
|-------------|---------------|
| Subtypes have different behavior (callbacks, validations, scopes) | Variants differ in label but follow same workflow |
| Conditional logic around type in 3+ places | Number of variants might grow beyond 4-5 |
| Each variant has a meaningful name | No behavioral difference between types |

---

## Table Queries (sort/filter)

**Queries belong to the model.** Anything that builds SQL is a scope or a class method on the model
that owns the data — including filter and search predicates. When a model accumulates several such
clusters, extract a model-specific concern (`app/models/concerns/{model}/{aspect}.rb`), per the
concern rule above.

**What a request is allowed to filter and sort is declared once, on the table's column set**
(`Core::Table::Column#sort_key` / `#filter`, `app/components/core/table/column.rb`). The controller
derives the whitelist from the same array it hands to the view (`Tableable#apply_table_params`,
`app/controllers/concerns/tableable.rb`) — one object, used twice, so it cannot drift. A sort or
filter cannot reach a field the table doesn't render, because the capability is declared on the
column that renders it.

**Sort/filter capability is per context, not per model.** One model exposed by two namespaces (e.g.
`Support::Ticket` via `/support/tickets` and `/adminit/tickets`) legitimately has two different
column sets, with different sortable/filterable fields and different row scopes. That is the
mechanism, not duplication to eliminate — a single whitelist keyed off the model can't express it.

**Row-level access is not a filter.** Which rows an index action may see belongs in the controller's
base relation, before `apply_table_params` runs. Filters `AND` onto that relation, so they can only
narrow — they can never be used to escape a scope like `where(created_id: current_account.id)`.

**Filter option lists that query an association go through a model scope named for their audience**
(`Role.selectable`, `Account.assignable`), not raw `Model.where(...)` in the helper. Rendering an
option list publishes its contents to anyone who can see the filter bar — that is a disclosure
decision, and it deserves a reviewable, named home.

**Role-conditional capability** (a column only some roles may sort/filter by) is a policy check
(`allowed_to?`) in the column-building helper, which removes the header, cell, sort link and filter
control together. Not built speculatively — `Permission::RESOURCE_REGISTRY` is resource-level only
today, so per-field capability isn't expressible yet. Escalate to it when a real requirement appears.

The escalation ladder for "where does this query go":

| Situation | Home |
|---|---|
| One-off lookup used by a single action | `where(...)` in the controller — fine, don't ceremony it |
| Reused or non-trivial predicate | Named scope on the model |
| Returns an aggregate/hash, not a relation | Class method on the model (`dashboard_stats`) |
| Model has 2+ query clusters and is getting long | Model concern (`Support::Ticket::Filterable`, `Account::Statistics`) |
| Needs `current_account` / request state | One-line lambda passed by the controller, over a model scope |
| No owning model at all, reused across domains | Reporting object in `app/services/` (not yet needed) |

This is the same ladder used for callbacks and interactors above: escalate on evidence, not in
advance.

---

## Interactor Rules

- Only rescue domain errors (`InvalidTransition`, `RecordInvalid`). Let code bugs bubble up.
- Wrap multi-model writes in transactions only when they target the **same database**.
- **Solid Queue uses a SEPARATE database** — `perform_later` is NOT part of the app's transaction.
- Use `Interactor::Organizer` for 4+ reusable steps. For 2-3 steps, a single interactor is simpler.
- Pass request context (IP, user-agent) explicitly — do NOT use `CurrentAttributes`.

---

## Background Job Rules

- Jobs must be **idempotent** — safe to run multiple times.
- Guards go in the job: record exists + timestamp matches.
- Do NOT add redundant state guards — the model's transition method raises `InvalidTransition`.
- For critical jobs, add a recurring **safety net** that catches missed records.
- Solid Queue on separate DB: if a job fails to enqueue after a state change, the state change still commits.

---

## Pagination

| Scenario | Approach |
|----------|----------|
| Admin tables, moderate data (< 100K) | `pagy` or `pagy_countless` |
| Infinite scroll feeds | `pagy_countless` with Turbo Frames |
| Chat/messages/audit logs (10K+, real-time inserts) | Cursor-based (`WHERE id < :cursor`) |
| API endpoints | `pagy` with `pagy/extras/headers` |

Cursor pagination uses the PK index directly — O(1) regardless of depth. `OFFSET` scans and discards rows.

---

## Real-Time Architecture

### Broadcasting Decision

| Scenario | Where to Broadcast |
|----------|-------------------|
| Simple CRUD sync | Model (`broadcasts_to`) |
| Workflow with notifications | Interactor |
| Conditional broadcasts | Interactor |
| User-specific broadcasts | Interactor or Controller |

### Channel Architecture

**One channel per concern.** Never route multiple features through a single channel with type flags.

| Mechanism | When |
|-----------|------|
| Turbo Streams (`broadcasts_to`) | Server pushes HTML. CRUD. One-directional. |
| Custom ActionCable Channel | Client sends AND receives. Typing, presence, live cursors. |

---

## Notification Rules

- Trigger notifications from **Interactors**, never from models.
- For bulk delivery (many recipients), enqueue a **background job** instead of delivering inline.
- Bulk delivery jobs must be **idempotent** — query already-notified recipients before delivering.

---

## I18n Rules

### File Organization

| Scope | Location |
|-------|----------|
| Used by 2+ domains | `config/locales/{locale}/shared.yml` |
| Specific to one domain | `config/locales/{locale}/{domain}.yml` |
| Model layer (enums, validations) | `config/locales/{locale}.yml` (root) |

### Key Rules

- **Explicit namespaced keys** (`t("adminit.tickets.updated")`), never lazy lookup
- **Enum display**: `t("enums.ticket.status.#{status}")`, never `.humanize`
- **Form labels**: always explicit `label: t(...)`, never auto-generated
- **System notes** (interactors): English only — internal audit records
- **Turbo broadcasts**: locale-neutral — render data, not translated labels
- **Always** add strings to both `en/` and `es/` locale files

---

## ViewComponent Rules

- Components live in `app/components/core/`
- Components never write ActiveRecord queries — data comes from model scopes/class methods
- `CustomFormBuilder` is the default form builder (set in `ApplicationController`)
- Lookbook previews at `/lookbook` in development

---

## JavaScript Architecture

| Location | Purpose |
|----------|---------|
| `controllers/` | Stimulus controllers — thin, orchestrate DOM |
| `models/` | Plain JS classes — complex logic, testable in isolation |
| `icons/` | SVG animation modules (`start`/`stop` exports) |
| `library/` | Shared utilities |

**Rule**: When a Stimulus controller grows past ~80 lines of non-DOM logic, extract to `models/`.

---

## File Organization

| Code Type | Location |
|-----------|----------|
| Models | `app/models/` (namespaced in subdirs) |
| Concerns | `app/models/concerns/` (model-specific in subdirs) |
| Controllers | `app/controllers/` (dashboard + adminit namespaces) |
| Interactors | `app/interactors/{domain}/` |
| Policies | `app/policies/` (mirrors controller structure) |
| Jobs | `app/jobs/` |
| Services | `app/services/external_services/` |
| Pipelines | `app/services/` |
| Notifiers | `app/notifiers/` |
| Components | `app/components/core/` |
| Config | `config/configs/` |
| JS Controllers | `app/javascript/controllers/` |
| JS Models | `app/javascript/models/` |
| Icons | `app/javascript/icons/` |
| Locales | `config/locales/{en,es}/{domain}.yml` |

---

## Summary: Where Does Code Belong?

| Code Type | Location |
|-----------|----------|
| Data validations | Model |
| State transition rules | Model (transition methods) |
| State queries for UI | Model (query methods) |
| Destroy protection | Model (before_destroy callback) |
| Simple CRUD broadcasts | Model (`broadcasts_to`) |
| Table filter/search SQL | Model scope (`search_title`, `assigned_to`, …) |
| Table sort/filter whitelist | `Core::Table::Column`/`Filter` on the column set (per context, not per model) |
| Table row-level access | Controller base relation, before filters apply |
| Filter option-list disclosure | Model scope named for its audience (`Role.selectable`) |
| Authorization (WHO) | Policy |
| Workflow orchestration | Interactor |
| Side effects (jobs, emails) | Interactor |
| Complex broadcasts | Interactor |
| External API calls | Service Object |
| Multi-step content processing | Pipeline (`app/services/`) |
| HTTP handling | Controller |
| UX guards | Controller |
| Typed configuration | Config class (Anyway Config) |
| DOM events, targets, lifecycle | Stimulus controller |
| Complex JS business logic | Plain JS class (`app/javascript/models/`) |
| Bidirectional real-time | Custom ActionCable channel (one per concern) |
