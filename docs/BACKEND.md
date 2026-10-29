---
name: backend
description: >
  Implement Ruby/Rails business logic — models, controllers, interactors, jobs, services, migrations, I18n, and broadcasts.
  Trigger: When writing Rails models, controllers, interactors, migrations, background jobs, service objects, or business logic.
license: Apache-2.0
metadata:
  author: mattszein
  version: "1.0"
---

## Role

You are a Backend Engineer. You implement Ruby/Rails code following the project's established patterns. You write models, controllers, interactors, jobs, services, policies, migrations, and handle I18n. You understand how broadcasts work (you configure them) but you don't build the receiving UI — that's frontend's job.

## When to Use

- Writing or modifying Rails models, migrations, validations, scopes
- Implementing controllers with authorization
- Building interactors for workflow orchestration
- Creating background jobs
- Writing service objects for external APIs
- Configuring broadcasts (`broadcasts_to`, `broadcast_*_later_to`)
- Adding I18n strings
- Setting up Anyway Config classes

---

## Tech Stack

| Component | Technology | Notes |
|-----------|-----------|-------|
| Database | PostgreSQL | Primary app database |
| Auth | Rodauth | `app/misc/rodauth_main.rb`, `app/misc/rodauth_app.rb` |
| Authorization | ActionPolicy | Custom RBAC in Adminit |
| Workflows | Interactor gem | `app/interactors/{domain}/` |
| Jobs | Solid Queue | PostgreSQL-backed, SEPARATE database from app |
| Cache | Redis | |
| WebSockets | AnyCable | High-performance Action Cable replacement |
| Config | Anyway Config | `config/configs/` |
| Notifications | Noticed gem | `app/notifiers/` |
| Frozen strings | Freezolite | Auto-adds `frozen_string_literal: true` (disabled in test) |

---

## Model Patterns

### File Organization Within a Model

```ruby
class Order < ApplicationRecord
  # 1. Extensions/DSL (has_secure_password, acts_as_*)
  # 2. Associations
  # 3. Enums
  # 4. Normalizations
  # 5. Validations
  # 6. Scopes
  # 7. Callbacks (transformers/normalizers only — score 4-5)
  # 8. Delegations
  # 9. Broadcasting (broadcasts_to)
  # 10. Public methods (query methods, then transition methods)
  # 11. Private methods
end
```

### Validations

Always in models — they're the last line of defense regardless of caller:

```ruby
validates :title, presence: true
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :scheduled_at, presence: true, if: :scheduled?

# State-based validations prevent invalid transitions
validate :cannot_update_when_published, on: :update

private

def cannot_update_when_published
  if status_was == "published"  # status_was = previous value
    errors.add(:base, I18n.t("activerecord.errors.models.announcement.attributes.base.cannot_update_published"))
  end
end
```

### Query Methods

Pure queries for UI visibility and controller guards. No side effects:

```ruby
def editable?
  !published?
end

def destroyable?
  draft?
end
```

### Transition Methods

State changes called by interactors. Pure database operations — **NO side effects**:

```ruby
def schedule!
  raise InvalidTransition, I18n.t("announcement.transitions.cannot_schedule_published") if published?
  raise InvalidTransition, I18n.t("announcement.transitions.already_scheduled") if scheduled?
  update!(status: :scheduled)
end

def publish!
  raise InvalidTransition, I18n.t("announcement.transitions.must_be_scheduled_first") unless scheduled?
  update!(status: :published, published_at: Time.current)
end
```

**NEVER** enqueue jobs, send emails, or trigger notifications from transition methods. Those belong in interactors.

### Custom Exceptions

```ruby
class Announcement < ApplicationRecord
  class InvalidTransition < StandardError; end
end
```

### Destroy Protection

```ruby
before_destroy :ensure_destroyable

private

def ensure_destroyable
  unless draft?
    errors.add(:base, I18n.t("activerecord.errors.models.announcement.attributes.base.only_draft_deletable"))
    throw(:abort)
  end
end
```

### Concerns

Cross-cutting concerns stay flat in `app/models/concerns/`. Model-specific concerns go in a subdirectory:

```
app/models/concerns/
  localizable.rb          # Cross-model → flat
  account/                # Model-specific → subdirectory when 2+ concerns
    notifiable.rb
    searchable.rb
```

```ruby
# app/models/concerns/account/notifiable.rb
module Account::Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  end
end
```

### Namespaced Models

Use when multiple models form a domain:

```ruby
# app/models/support/ticket.rb
module Support
  class Ticket < ApplicationRecord
    self.table_name = "tickets"
  end
end
```

Tables use the simple name (`tickets`, not `support_tickets`) unless there's a collision.

### Broadcasting from Models

Use `broadcasts_to` for **simple CRUD sync** only:

```ruby
broadcasts_to ->(ticket) { "tickets" },
  partial: "support/tickets/ticket_table"

after_create_commit do |ticket|
  broadcast_append_later_to "admin_tickets",
    target: "admin_tickets",
    partial: "adminit/tickets/ticket_row"
end
```

**IMPORTANT**: `dom_id` is NOT available in model context. Use:

```ruby
ActionView::RecordIdentifier.dom_id(record, "prefix")
```

For workflow/conditional broadcasts, use `Turbo::StreamsChannel.broadcast_*` in the Interactor instead.

---

## Table Filters & Sorting

Recipe for an indexed, sortable, filterable table (see `docs/ARCHITECTURE.md` → Table Queries for the
rule this implements):

**1. SQL is a model scope:**

```ruby
# app/models/support/ticket.rb
scope :search_title, ->(query) { where("title ILIKE ?", "%#{sanitize_sql_like(query)}%") }
scope :assigned_to,  ->(account_id) { where(assigned_id: account_id) }
```

**2. The whitelist is declared once, on the column that renders the field** (helper the view already
calls — `app/helpers/{namespace}/{resource}_helper.rb`):

```ruby
Core::Table::Column.new(
  label: I18n.t("shared.labels.title"),
  renderer: ->(ticket) { ticket.title },
  sort_key: :title,
  filter: Core::Table::Filter.new(type: :text, param: :search, scope: :search_title)
)
```

`scope:` omitted → `Tableable` applies exact match `where(param => value)`, and raises in dev/test if
`param` isn't a real column (catches typos instead of silently no-opping the control). `scope:`
present → `relation.public_send(scope, value)`.

**3. The controller assigns the column set once and passes it to both the query and the view:**

```ruby
def index
  authorize! Support::Ticket, with: Adminit::TicketPolicy
  @columns = helpers.ticket_columns
  @pagy, @tickets = apply_table_params(
    Support::Ticket.includes(:created, :assigned).prioritized,  # row-level access lives here
    columns: @columns
  )
end
```

```erb
<%= render Core::TableComponent.new(rows: @tickets, columns: @columns, options: { sortable: true, filterable: true, pagy: @pagy }) %>
```

Passing `@columns` to both means the whitelist and the rendered header set are the same object at
runtime — they cannot drift apart.

**4. Context filters (need `current_account`, "now", tenant) are not built yet** — no caller needs one.
When one appears, it is an explicit lambda the controller merges in over the column-derived filters,
not a macro on the model. The model stays free of request state.

**5. Association-backed filter options go through an audience-named scope**, not a raw query in the
helper:

```ruby
# app/models/account.rb
scope :assignable, -> { where.not(role_id: nil).order(:email) }
```

```ruby
filter: Core::Table::Filter.new(type: :select, param: :assignee, scope: :assigned_to,
  options: -> { Account.assignable.pluck(:email, :id) })
```

Rendering an option list publishes its contents to anyone who can see the filter bar — treat that as
a disclosure decision, not a convenience query.

**One model, two contexts, two column sets.** `Support::Ticket` is exposed at `/support/tickets`
(owner-scoped, `category` filterable) and `/adminit/tickets` (all rows, `priority` sortable). Each
namespace's helper declares its own column set — that split is intentional, not duplication.

### Full-Text Search (Support::Article)

`Support::Article.search(query, locale:, category:, limit:)` (admin) and `Support::Article.published_search(query, locale:, category:, limit:)` (help center, suggestions and the AI: published only) query a generated, stored `searchable`
tsvector column (GIN-indexed; title weight A, summary B, body C) with `websearch_to_tsquery('simple', ...)`.
Rich text can't be indexed directly, so `search_text` is synced from `body.to_plain_text` in a
`before_save`. Relevance ties are broken by newest `published_at`. Passing a `category` also matches `general` articles. The article category enum is `Support::Ticket::CATEGORIES` plus a real `general` value (`Support::Article::GENERAL_CATEGORY = 100`, the column default; never nil), so tickets and articles never drift.

---

## Feature Flags

Operator-controlled release gates: a flag holds an access list of reusable **audiences** and
per-account **allow/block** entries, evaluated in-process against committed database state. See
`docs/ARCHITECTURE.md` → Feature Flags for the entry-point and no-attribution-column rules this
implements.

**Pieces:**

| Piece | File | Role |
|---|---|---|
| Flag / condition registries | `app/lib/feature_flags/registry.rb`, `app/lib/audience_conditions/registry.rb` | In-memory declared sets (`DeclaredRegistry`). |
| Declarations | `app/lib/feature_flags/flags.rb`, `app/lib/audience_conditions/vocabulary.rb` | One `Registry.register(...)` call per flag/condition. Ships with one demo flag (`test_feature_flag`, seeded with a superadmin audience and gating a dashboard banner) — replace it with your own. |
| Decision | `app/models/feature_flags.rb`, `app/models/feature_flags/account_evaluator.rb` | `FeatureFlags.for(account)` / `.enabled?(key, account)` — the only entry points. |
| Consumption | `app/controllers/concerns/feature_gated.rb` | `feature_enabled?(key)`, `require_feature!(key)`, included on `SharedBaseController`. |
| State | `FeatureFlag`, `Audience`, `AudienceCondition`, `FeatureFlagAudience`, `FeatureFlagAccount` | Access-list rows — read directly only to *display*, never to decide. |
| Admin | `Adminit::{FeatureFlagsController,AudiencesController}` | Flag list/detail (attach/detach an audience, allow/block an account as member actions on the flag), audience CRUD + archive — single-row writes, no interactor. |

**Declare a flag:**

```ruby
# app/lib/feature_flags/flags.rb
Registry.register(:new_dashboard)
```

```yaml
# config/locales/en/feature_flags.yml (and es/)
en:
  feature_flags:
    flags:
      new_dashboard: {name: "New dashboard", description: "The redesigned account dashboard."}
```

Run `bin/rails feature_flags:sync` to materialize its row (this also runs automatically as part of
`db:prepare`, so a deploy picks up a newly declared flag with no manual step; `db:migrate` and
`db:schema:load` do not run it). It then shows in Adminit → Feature Flags, off for everyone until an operator attaches
an audience or account entry.

**Gate a capability:**

```ruby
before_action { require_feature!(:new_dashboard) }  # 404s, reusing the app's not-found handling
```

```erb
<% if feature_enabled?(:new_dashboard) %><%= render NewDashboardComponent.new(...) %><% end %>
```

**Register an audience condition:**

```ruby
# app/lib/audience_conditions/vocabulary.rb
Registry.register(
  key: :on_paid_plan,
  type: :boolean, # :affirmative (off/true only) | :id_list (accepts: names the model) | :duration ({amount:, unit:})
  accepts: [true, false],
  predicate: ->(account, value) { account.paid? == value } # only account + value — no query of its own, and the answer must not move with the clock (a fixed age threshold is the one allowed exception)
)
```

Add its label/hint/value vocabulary to both locale files (`config/locales/{en,es}/audience_conditions.yml`).
Nothing else changes — the audience form renders the partial named by `type`; a new value *type* needs
one new partial under `app/views/adminit/audiences/conditions/`.

**Retire a flag:** delete its `Registry.register` line. The row and its access-list history stay;
`FeatureFlag.declared` stops returning it (Adminit no longer lists it, `FeatureFlags.enabled?` returns
`false`, logged not raised). An audience only attached to that flag is free to reuse elsewhere.

**Attach an audience, or allow/block an account** — both are Adminit actions on a flag's detail page,
no code change: a block always wins, an explicit allow beats any audience, otherwise any matching
attached audience grants.

**Account lookup:** every admin screen with a searchable account picker (roles, feature flags, the
dashboard widget) shares one endpoint, `Adminit::AccountsController#search`
(`GET /adminit/accounts/search`).

---

## Support AI

The support assistant (see `docs/PROJECT.md`) is a set of interactors run from a job, an LLM facade (`SupportAi::Responder`) and a capability registry. Behavior lives in data (`Support::AiPlaybook` rows); code only declares what is possible.

**The three rules**
- **Context = prefetched in code.** What the model needs (requester facts, their own past tickets, matching help-center articles) is put into the first user prompt by `SupportAi::Context`. The model never has to ask for it.
- **Tools = model-initiated queries only.** The single tool is `search_articles` (refined help-center searches).
- **Outcomes = JSON fields of the answer.** `{reply, article_ids, resolution_proposed, handoff, handoff_reason}`. There are no action tools (no suggest/propose/request-human tools), and the model never writes to the database.

### Pipeline

Triggered by `Support::AiProcessJob` (queue `support_ai`). Organizers live in `app/interactors/support/ai/flows/`, steps in `app/interactors/support/ai/`.

| Flow | Steps |
|------|-------|
| `Flows::ProcessTicket` (ticket created) | `Triage -> SelectPlaybook -> ApplyTriage -> Handle -> Finalize` |
| `Flows::ProcessReply` (user wrote while the AI owns the ticket) | `SelectPlaybook -> Respond -> Finalize` |

| Step | What it does | On failure |
|------|--------------|------------|
| `Triage` | One structured LLM call (category, priority, language, escalate). Runs first because the playbook is chosen from its result. A retry reuses an already succeeded triage run | **Non-fatal**: failed run logged, pipeline continues with the ticket's own category/priority |
| `SelectPlaybook` | `Support::AiPlaybook.match_for(ticket, priority:)` (see below) | No playbook: new ticket -> `ai_state off`; ongoing conversation -> `Fallback`. Organizer stops |
| `ApplyTriage` | Applies only what the playbook allows (`auto_set_priority`, `auto_correct_category`), only when the value differs, in ONE `update!`, with one English system note per change | DB error bubbles up |
| `Handle` | `Responder#handle`: one chat, one `ToolBudget`, two turns. Turn 1 writes the findings for admins, turn 2 returns the answer JSON. `triage_only` playbooks and escalated triage run turn 1 only | **Fatal**: failed run logged, error re-raised for retry |
| `Respond` | `Responder#respond`: answers a follow-up using the ticket's earlier succeeded `triage`/`handle` outputs. Skipped for `triage_only` or escalated triage | **Fatal** |
| `Finalize` | All DB writes, under `ticket.with_lock` (short, DB only) | See Handoff |

Never let an optional step stop the user from getting an answer.

**Job guards and retries**: the job returns early unless `ai_analyzing?`, debounces bursts (only the newest human message acts) and skips a message that already has an AI answer. `retry_on SupportAi::Error` (3 attempts, polynomial backoff); when retries run out `Fallback` hands the ticket to a person with the fixed handoff reply plus a `system` note. `Fallback` is idempotent (acts only while the AI still owns the ticket). `Dispatch` enqueues the job; an enqueue failure is logged and never undoes the state change before it.

### Responder, Context, ToolBudget

- **`SupportAi::Responder`** is pure: it returns a `SupportAi::Result` (output, model, tokens, latency, tool calls, transcript) or raises `SupportAi::Error`. It performs no DB writes; interactors persist.
- **Handle answer parsing**: plain-text JSON parsed tolerantly, one retry, then `SupportAi::Error`. `article_ids` survive only if the model saw them (prefetched or returned by `search_articles` in this step) and they are still published (max 3). `handoff`/`resolution_proposed` are coerced to booleans.
- **`SupportAi::Context`** (plain Ruby) builds one block per enabled context capability, each wrapped as untrusted: `account_facts` (requester only: status, verified, member since, role; no email), `past_tickets` (requester's own, max 10) and the retrieval-first article prefetch (`search_articles`: ticket text, `[[:alnum:]]` words, ~300 chars, user's locale first then any, published only, top 3 with id/slug/locale/title/summary/excerpt). The prefetch is recorded on the budget, so it counts as a found article.
- **`SupportAi::ToolBudget`** (`SupportAiConfig.max_tool_calls`, default 10) is shared by every tool of a step. Identical calls are served from cache (not counted); once spent, tools return "Tool limit reached" so the model answers; a model that keeps calling (3 more attempts) aborts the step with `SupportAi::Error`. It also tracks `searched_queries` and `found_article_ids`.
- **Transcripts**: `Responder#run_step` builds a `SupportAi::Transcript` from the chat on success and on failure (`Result#transcript`, `Error#transcript`/`#tool_calls`), so failed runs are inspectable.

### Admin note, help-center line, similar tickets

ONE `ai` note per AI pass. `Handle` writes the findings (1-2 factual English sentences, max 40 words, truncated at 1,200 chars) followed by deterministic lines built by code:
- `Help center: <attached article titles>` or `Help center: no article answered this.`
- with `similar_tickets` enabled: `Similar resolved tickets: #12 title (2026-09), ...` (other requesters' finished tickets via `Support::Ticket.resolved_similar_to`). It is admin only, runs no LLM and never enters a prompt.

`Handle` sets `context.note_written`; `Finalize` then writes no second note. A handoff pass where `Handle` wrote none (`ProcessReply`, or no `investigate_note`) gets `AI handoff: <reason>` from `Finalize`, no LLM call. The user's "Talk to a person" button (and "I still need help") is allowed only while `awaiting_user` (`TicketPolicy#request_human?`), never mid-run; it writes a system note `User requested a human`.

### KB gap

`kb_gap` is true when the playbook has `search_articles` and neither the prefetch nor any search the model ran found an article. It is computed in code in `Responder#handle`, never by the model. On a gap the turn-2 request carries a "no guide matched" directive and the handoff is forced (`KB_GAP_HANDOFF_REASON`; the model's own reason wins if it set one). The `handle` run output stores `kb_gap` and `kb_queries` (max 3). The only admin-facing trace is the note's `Help center:` line. Playbooks without `search_articles` never report a gap; `triage_only` still computes it for the run output. The gap is enforced in `handle` only.

### Handoff

- **Triggers** (in `Finalize`): the answer's `handoff` (including a forced KB gap), triage `escalate`, `triage_only` mode, or `max_ai_turns` reached.
- **Fixed reply**: on any handoff the user message is the localized `support.ai.handoff_message` (locale from triage language, else `I18n.locale`), never the model's reply. `triage_only` posts no message. `Fallback` uses the same key.
- **Under the lock** `Finalize` re-checks that the AI still owns the ticket (`ai_analyzing?`) and that no newer human message exists; otherwise the reply is discarded and the run marked `discarded`.
- **Grounding**: screens, menus, buttons, URLs or steps may be described only if they appear in an article given in the prompt, one returned by `search_articles`, or the playbook instructions; never state that the product has or lacks a feature unless an article says so (`Prompts.grounding`). Wording is not trusted for the no-article case: that is what the KB gap enforces.

### ai_state

`Support::Ticket#ai_state`, changed only through transition methods (each raises `InvalidTransition` from a wrong state):

| Method | From -> to |
|--------|-----------|
| `start_ai_analysis!` | `off` / `awaiting_user` -> `analyzing` |
| `disable_ai!` | `analyzing` -> `off` |
| `await_user_reply!` | `analyzing` -> `awaiting_user` |
| `request_ai_handoff!` | `analyzing` / `awaiting_user` -> `handoff_requested` |
| `release_ai!` | any engaged state -> `stepped_back` (assignment of the ticket, e.g. Take) |
| `resolve_with_ai!` | `awaiting_user` (ticket open) -> `resolved`, status `finished` |

### Playbooks and matching

`Support::AiPlaybook.match_for(ticket, priority:)` (triaged priority, else the ticket's): among enabled non-default playbooks whose conditions fit, the highest `specificity` wins (count of set conditions: categories, a priority bound, audience); ties go to the lowest id (oldest); otherwise the enabled default; otherwise none. Nothing is stored on the ticket and there is no manual ordering; every pass re-matches with the current rules. The index shows the specificity badge.

### Audit: AiRun

`Support::Ai::RecordRun` writes one `Support::AiRun` per step (trigger, step, status `succeeded`/`failed`/`discarded`, model, tokens, latency, `tool_calls`, `transcript`, `output`, error). Record a run for every new LLM step. `playbook_snapshot` (jsonb, `RecordRun.snapshot_for`: name, mode, capabilities, instructions, limits, conditions) freezes the rules used, so history survives playbook edits; `playbook_id` is only a link and is nullified when the playbook is deleted. `AiRun.step :investigate` is legacy (kept so old rows load).

The admin ticket's "AI activity" panel opens each run in a modal (`Adminit::Tickets::AiRunsController#show`, rendered by `Adminit::Tickets::AiRunTranscriptComponent`, which takes the run and never queries). It shows header facts, the snapshot, the error, the transcript (system/user/assistant/tool entries, tool calls with JSON arguments) and the output. Authorization mirrors `Adminit::TicketsController#show` and the run is found through `ticket.ai_runs`. Transcript content is always escaped (`Core::CodeBlockComponent`, never `raw`); runs from before transcripts existed show a "no transcript" note.

### Capability registry

`Support::AiCapabilities` / `Support::AiCapability` (`app/models/support/`, re-declared on reload by `config/initializers/support_ai_capabilities.rb`). Each capability declares `key`, `kind`, the pipeline `steps` (`handle respond apply_triage draft`), a `tool_class` name or nil, and `default` (enabled on the seeded default playbook). Playbooks store enabled keys; validation rejects unregistered keys; `AiCapabilities.for_step` is the only gate between a playbook and what a step uses.

| Kind | Meaning | Keys |
|------|---------|------|
| `context` | prefetched into the prompt | `account_facts`, `past_tickets` |
| `tool` | model-callable | `search_articles` (also drives the prefetch and KB gap) |
| `flag` | code switch | `similar_tickets`, `vision_attachments`, `investigate_note`, `auto_set_priority`, `auto_correct_category`, `draft_replies` |

**Security boundary**: other users' data never enters a user-facing prompt. `similar_tickets` reads other requesters' tickets, so it is a code-only flag feeding the admin note line. Context blocks and tools are scoped to the ticket's requester.

**Adding a capability**:
1. Register it in `Support::AiCapabilities.install` with the right `kind`, `steps` and `default`
2. Context: add a block to `SupportAi::Context`. Tool: add `SupportAi::Tools::<Name>` (inherit `Tools::Base`, scope queries to the requester, minimal fields)
3. Add `support.ai.capabilities.<key>` label/hint translations in en and es
4. Add specs: registry/tool spec, and a Responder or workflow example using it

### Prompts

All prompts live in one file, `app/services/support_ai/prompts.rb`. Keep them token-lean: short imperative sentences, no repeated rules across system and user prompts, shared parts (`Prompts.grounding`, reply format) defined once. Every user-controlled or third-party value (ticket text, messages, article text, account facts, tool results) is wrapped with `Prompts.untrusted` in `<<<MARKER ... MARKER>>>` delimiters, and the system prompt tells the model never to follow instructions inside them. Use `Prompts.untrusted` for any new field you inject. The marker word is `SupportAiConfig.untrusted_marker` (env `SUPPORT_AI_UNTRUSTED_MARKER`, default `UNTRUSTED`).

### Other

- **Search fallback**: `Support::Article.search` runs the AND `websearch_to_tsquery('simple', ...)` first and, when it finds nothing, retries as an OR of prefix terms (3+ chars, max 8, sanitized) with a minimum rank. The AI never filters by category (its classification can be wrong).
- **AI message author**: `messages.sender` enum (`human`/`ai`) with a nullable `account_id`; check constraint `messages_sender_account_check` guarantees human messages have an account and AI messages do not. Notes use `kind: :ai` with `account: nil`. Never fake an account for AI output.

### Config

`SupportAiConfig` (`config/support_ai.yml`, Anyway Config): `enabled` (global kill switch, env `SUPPORT_AI_ENABLED`, default false), `model`, `vision_model` (used when a playbook enables `vision_attachments`), `temperature`, `history_limit`, `max_tool_calls`, `timeout`, `untrusted_marker` (env `SUPPORT_AI_UNTRUSTED_MARKER`). Every attr can be overridden with `SUPPORT_AI_<ATTR>`; the provider key is `OPENROUTER_API_KEY` (RubyLLM). Everything else (mode, capabilities, limits, conditions, instructions) is a playbook row; the default playbook is seeded in `db/seeds.rb`.

### Specs

Never hit the network.
- Workflow, job and interactor specs: `spec/support/support_ai_workflow_helpers.rb`: `stub_responder(triage: ai_result(...), handle: ai_result(...), respond: ai_result(...))` replaces `SupportAi::Responder`; pass an exception class to simulate failure
- Responder/tool specs (`type: :service` or `:llm`): `spec/support/support_ai_llm_helpers.rb`: `stub_llm(text_body("..."), tool_call_body([[name, args]]))` stubs only the HTTP layer so the real tool loop runs; wrap in `with_openrouter_key`

---

## Controller Patterns

### Standard Structure

```ruby
class Adminit::TicketsController < Adminit::ApplicationController
  before_action :require_account
  verify_authorized

  def index
    @tickets = authorized_scope(Support::Ticket.all)
  end

  def show
    @ticket = Support::Ticket.find(params[:id])
    authorize! @ticket
  end

  def update
    @ticket = Support::Ticket.find(params[:id])
    authorize! @ticket

    if @ticket.update(ticket_params)
      redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def ticket_params
    params.require(:ticket).permit(:title, :category, :status)
  end
end
```

### Critical Controller Rules

- **ALWAYS** add `before_action :require_account` — without it, `current_account` is nil (Rodauth rack middleware doesn't run in controller context)
- **ALWAYS** add `verify_authorized` — ensures every action calls `authorize!`
- Use `:unprocessable_content` NOT `:unprocessable_entity` (Rack deprecation)
- For Turbo Frame actions: `ensure_frame_response` before_action redirects before the action body runs
- Modal create/update forms: `include ModalFormResponses` and use `respond_success(message, path)` / `respond_form_error(action)`; define a private `modal_form_locals` (locals for the `_form` partial; the frame id is `<singular controller name>_form`)

### Workflow Actions

For actions with side effects, delegate to interactors:

```ruby
def schedule
  result = Announcements::Schedule.call(announcement: @announcement)

  if result.success?
    redirect_to @announcement, notice: I18n.t("adminit.announcements.scheduled")
  else
    redirect_to @announcement, alert: result.error
  end
end
```

---

## Interactor Patterns

### Basic Structure

```ruby
module Announcements
  class Schedule
    include Interactor

    delegate :announcement, to: :context

    def call
      announcement.schedule!
      enqueue_publish_job
    rescue Announcement::InvalidTransition, ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end

    private

    def enqueue_publish_job
      PublishAnnouncementJob
        .set(wait_until: announcement.scheduled_at)
        .perform_later(announcement.id, announcement.scheduled_at.to_i)
    end
  end
end
```

### Error Handling

Only rescue domain errors. Let code bugs bubble up to error trackers:

```ruby
rescue Model::InvalidTransition, ActiveRecord::RecordInvalid => e
  context.fail!(error: e.message)
# StandardError, NoMethodError, etc. → bubble to Sentry/Honeybadger
```

### Transactions

Wrap multiple database writes in a transaction when they target the **same database**:

```ruby
def call
  ActiveRecord::Base.transaction do
    record_a.update!(...)
    record_b.update!(...)
  end
end
```

**CRITICAL**: Solid Queue uses a SEPARATE database. `perform_later` is NOT part of the application's transaction. If a job fails to enqueue after a state change, the state change still commits. Rely on safety-net recurring jobs to catch anything that slips through.

### Organizer

Use `Interactor::Organizer` when 4+ steps with reusable steps and rollback logic. For 2-3 steps, a single interactor is simpler.

### Request Context

Pass context explicitly — do NOT use CurrentAttributes:

```ruby
# Controller
Tickets::Assign.call(ticket: @ticket, assignee: account, ip_address: request.remote_ip)

# Interactor receives it explicitly
delegate :ticket, :assignee, :ip_address, to: :context
```

---

## Background Jobs

### Structure

```ruby
class PublishAnnouncementJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(announcement_id, expected_scheduled_at)
    announcement = Announcement.find_by(id: announcement_id)

    # Idempotency guards
    return unless announcement
    return if announcement.scheduled_at.to_i != expected_scheduled_at

    result = Announcements::Publish.call(announcement: announcement)

    if result.failure?
      Rails.logger.error("PublishJob Failed for Announcement #{announcement_id}: #{result.error}")
    end
  end
end
```

### Idempotency Guards

Jobs must be safe to run multiple times:

- Record exists? (handle deleted records)
- Timestamp matches? (detect stale jobs after reschedule)

Do NOT add redundant state guards — the model's transition method raises `InvalidTransition` if the state is wrong.

---

## Authorization (ActionPolicy)

### Policy Structure

```ruby
module Adminit
  class AnnouncementPolicy < ApplicationPolicy
    POLICY_RESOURCE = :announcement
    self.identifier = :"Adminit::AnnouncementPolicy"
    # All actions use default manage? rule
  end
end
```

### Adding a New Resource

1. Add to `Permission::RESOURCE_REGISTRY` (integer enum — NEVER reuse values)
2. Create policy with `POLICY_RESOURCE` matching the enum key
3. Set `self.identifier` for ActionPolicy

---

## Notifications (Noticed)

```ruby
class AnnouncementNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "AccountMailer"
    config.method = "new_announcement"
  end

  deliver_by :custom do |config|
    config.class = "DeliveryMethods::TurboStream"
  end

  required_param :message

  notification_methods do
    def title = t(".title")
    def subtitle = record.title
    def notification_type = "announcement"
  end
end
```

Trigger notifications from interactors, never from models. For bulk delivery, enqueue a background job.

---

## I18n Conventions

### File Organization

```
config/locales/
  en.yml / es.yml          # Model layer: ActiveRecord, enums, transitions
  en/ & es/
    shared.yml             # Cross-domain (used by 2+ domains)
    adminit.yml            # Admin area
    support.yml            # Support area
    settings.yml           # Settings
    rodauth.yml            # Auth pages
    mailers.yml            # Emails
```

**Decision rule**: used by 2+ domains → `shared.yml`; specific to one domain → that domain's file; model-layer → root `en.yml`/`es.yml`.

### Usage Rules

- Controllers: `I18n.t("adminit.tickets.updated")` — explicit namespaced keys, NOT lazy lookup
- Enums: `t("enums.ticket.status.#{status}")` — never `.humanize`
- Form labels: always pass explicit `label: t(...)` — never rely on auto-generation
- System notes in interactors: keep in English (internal audit records)
- Turbo broadcasts: keep locale-neutral (render data, not translated labels)
- **ALWAYS** add strings to both `en/` and `es/` locale files

---

## Pagination

### Default: Pagy

```ruby
# Infinite scroll (no COUNT query)
@pagy, @records = pagy_countless(scope, limit: 20)

# Standard (with total count)
@pagy, @records = pagy(scope)
```

### Cursor-Based (high-volume)

```ruby
# In model concern
scope :before_cursor, ->(id) { where("id < ?", id).order(id: :desc).limit(PAGE_SIZE) }
scope :after_cursor, ->(id) { where("id > ?", id).order(id: :asc).limit(PAGE_SIZE) }
```

Use cursor for chat/messages/audit logs with 10K+ records and real-time inserts.

---

## Service Objects

For external API integrations:

```ruby
module ExternalServices
  class StripeClient
    def initialize(api_key: Rails.application.credentials.stripe_api_key)
      @client = Stripe::Client.new(api_key)
    end

    def create_charge(amount:, currency:, source:)
      @client.charges.create(amount: amount, currency: currency, source: source)
    rescue Stripe::Error => e
      Result.failure(e.message)
    end
  end
end
```

### Pipeline Pattern (multi-step processing)

```ruby
module ContentPipeline
  FILTERS = [Filters::SanitizeHtml, Filters::LinkifyUrls].freeze

  def self.apply(content)
    FILTERS.reduce(content) { |c, filter| filter.new(c).apply }
  end
end
```

---

## Configuration (Anyway Config)

```ruby
# config/configs/application_config.rb
class ApplicationConfig < Anyway::Config
  attr_config :app_name, :default_from_email
end

# Usage
ApplicationConfig.new.app_name
```

---

## Docker Commands

Always run through Docker:

```bash
# Tests
docker compose exec -e RAILS_ENV=test rails bundle exec rspec
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb:10

# Database
docker compose exec rails bin/rails db:migrate
docker compose exec rails bin/rails db:seed

# Linting
docker compose exec rails bin/rubocop
docker compose exec rails bin/rubocop -a
```

## Rules

- NEVER write view code, components, or CSS — that's frontend's job
- NEVER skip `before_action :require_account` on user-facing controllers
- NEVER add side effects to model transition methods
- NEVER hardcode user-facing strings — always use I18n
- ALWAYS add I18n keys to BOTH `en/` and `es/` files
- ALWAYS use `:unprocessable_content` not `:unprocessable_entity`
- ALWAYS use `ActionView::RecordIdentifier.dom_id` in model context (not `dom_id`)
- Use `status_was` (not `status`) when checking previous value in validations
- Integer enum values in `Permission::RESOURCE_REGISTRY` must NEVER be reused
