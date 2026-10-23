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

`Support::Article.search(query, locale:, category:, limit:)` queries a generated, stored `searchable`
tsvector column (GIN-indexed; title weight A, summary B, body C) with `websearch_to_tsquery('simple', ...)`.
Rich text can't be indexed directly, so `search_text` is synced from `body.to_plain_text` in a
`before_save`. Chain `.published` to restrict to public articles; passing a `category` also matches
general (nil) articles. The category enum reuses the shared `Support::Ticket::CATEGORIES`, so tickets
and articles never drift.

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

The support assistant (see `docs/PROJECT.md`) is a set of interactors run from a job, an LLM facade, and a capability registry. Behavior lives in data (`Support::AiPlaybook` rows); code only declares what is possible.

**Workflow** (`app/interactors/support/ai/`), triggered by `Support::AiProcessJob` (queue `support_ai`):

- `ProcessTicket` (on creation): `Triage → SelectPlaybook → ApplyTriage → Handle → SimilarCases (optional) → Finalize`
- `ProcessReply` (user wrote while the AI owns the ticket): `SelectPlaybook → Respond → Finalize`
- Why triage is its own call: the playbook (tools, instructions, mode) is chosen from triage's category and priority, so it must run first (structured output, no tools).
- `Handle` = ONE RubyLLM chat, ONE `ToolBudget`, two turns (`Responder#handle`, step `handle`, UI "Investigation and reply"). Turn 1 sees the ticket and the triage result and writes internal findings for the admin (stored as the `ai` note when the playbook has `investigate_note`); turn 2, same chat so tool results stay in context, writes the reply to the user. `triage_only` playbooks and escalated triage run turn 1 only (`context.reply` nil). Tools are the `:respond` step set only.
- `SimilarCases` (optional, admin-only, non-fatal): when the playbook enables `similar_tickets`, `Responder#investigate` writes a second `ai` note ("Similar past cases: ..."). Skipped on a retry if any `investigate` run already exists. Its output never feeds a user-facing prompt.
- `Respond` (follow-up user messages) now also receives the ticket's succeeded `triage` and `handle` outputs (`ticket.ai_runs.latest_output(step)`); safe because the findings derive from respond-safe tools only.
- `Finalize` does all DB writes under `ticket.with_lock` after the LLM work is done (short, DB-only lock). Inside the lock it re-checks the AI still owns the ticket (`ai_analyzing?`) and that no newer human message exists; otherwise the reply is discarded. The handoff summary (an LLM call) runs after the lock.
- Run viewer: the admin ticket's "AI activity" panel links each run to `Adminit::Tickets::AiRunsController#show` (modal, `adminit_ticket_ai_run_path(ticket_id:, id:)`), rendered by `Adminit::Tickets::AiRunTranscriptComponent` (takes the run, never queries). It shows header facts, the error, the recorded `transcript` (system/user/assistant/tool entries, tool calls with JSON arguments) and the `output`.
- Authorization mirrors `Adminit::TicketsController#show` (`Adminit::TicketPolicy#show?`), and the run is found through `ticket.ai_runs`, so a run can't be read through another ticket. Transcript content is always HTML-escaped (never `raw`); runs created before transcripts existed show a "no transcript" note.
- `Fallback` hands the ticket to a person with a generic message. Idempotent; called when retries run out or no playbook exists.

**Job guards and retries**: the job returns early unless `ai_analyzing?`, debounces bursts (only the newest human message acts), and skips a message that already has an AI answer. `retry_on SupportAi::Error` (3 attempts, polynomial backoff); the exhausted block calls `Fallback`. Retries reuse earlier successful steps (e.g. a succeeded triage run) instead of paying again.

**Fatal vs non-fatal steps**: `Triage` and `SimilarCases` rescue `SupportAi::Error`, log a failed run and let the pipeline continue. `Handle` and `Respond` errors are fatal (raised for retry). Never let an optional step stop the user from getting an answer.

**Capability registry** (`app/lib/support_ai/capabilities.rb`, hot-reloaded via `config/initializers/support_ai_capabilities.rb`): each capability declares `key`, `kind` (`:read`/`:action`), the pipeline `steps` it may run in, a `tool_class` name (String) or nil, and `default` (enabled on the seeded default playbook). Playbooks store enabled keys; validation rejects unregistered keys; the `Responder` only builds tools for capabilities that are both enabled and allowed in the current step.

**Security boundary**:
- The user-facing `handle` and `respond` steps must never see other users' data. `similar_tickets` reads other requesters' tickets, so it is declared for `:investigate` only (the admin-only `SimilarCases` call; `handle` uses the `:respond` tool set) and returns title, category and month only
- Every tool is scoped to the ticket's requester (`account_facts`, `past_tickets` read only their own data)
- Prompts (`app/services/support_ai/prompts/`) wrap every user-controlled value in `<<<UNTRUSTED ... UNTRUSTED>>>` markers and instruct the model to never follow instructions inside them, including tool results. Use `Prompts::Base.untrusted` for any new field you inject

**AI message author**: `messages.sender` enum (`human`/`ai`) with a nullable `account_id`; check constraint `messages_sender_account_check` guarantees human messages have an account and AI messages do not. Notes follow the same idea with `kind: :ai` and `account: nil`. Never fake an account for AI output.

**Logging**: `Support::Ai::RecordRun` writes one `Support::AiRun` per step (trigger, step, status `succeeded`/`failed`/`discarded`, model, tokens, latency, tool calls, error). It powers the admin AI activity panel; record a run for every new LLM step.

**Tool budget and transcripts**: each Responder step shares a `SupportAi::ToolBudget` (`SupportAiConfig.max_tool_calls`, default 10) with its tools. `Tools::Base#call` serves identical calls from cache (not counted) and, once the budget is spent, returns a "Tool limit reached" error instead of running `execute`, so the model writes its final answer. Only a model that keeps calling after that (3 more attempts) aborts the step with `SupportAi::Error`. `Responder#run_step` builds a `SupportAi::Transcript` from the chat on both paths (on `Result#transcript` and on `Error#transcript`/`#tool_calls`) and `RecordRun` stores them on `support_ai_runs.transcript`/`tool_calls`, so failed runs are inspectable.

**Config**: global kill switch and model settings in `SupportAiConfig` (`config/support_ai.yml`, env `SUPPORT_AI_ENABLED`, `OPENROUTER_API_KEY` via RubyLLM). Everything else (mode, capabilities, limits, conditions) is a playbook row; the default playbook is seeded in `db/seeds.rb`.

**Grounding rule**: the assistant describes app screens, menus, buttons, URLs or steps ONLY when they appear in a help-center article provided in the prompt, an article returned by `search_articles` in this conversation, or the playbook instructions (`Prompts::Base::GROUNDING`, in the Handle and Respond system prompts). If an article covers the question it summarizes briefly and attaches the article it used with `suggest_articles`; if none does it says it found no guide and calls `request_human`. Prompt wording is not trusted for the no-article case, see KB gap.

**Retrieval-first KB**: the model does not decide whether to search first. When the playbook has `search_articles`, `Responder#handle` (before turn 1) and `#respond` (before the final ask) search the help center in code with the ticket text (`prefetch_articles`: title + description, or the latest requester message + title for `respond`; `[[:alnum:]]` words only, ~300 chars; the user's locale first, then any locale; published only, top 3). The matches go into the USER prompt through `Prompts::Base#kb_block` (id, slug, locale, and title/summary/`Article#excerpt` (1,200 chars of plain text) each wrapped as untrusted; or a "no article matched, you may try refined searches" line). The prefetch is recorded on the `ToolBudget` (`note_search`), so it appears in `kb_queries` and counts as a found article. Prompt only: nothing is written to the database. The `search_articles` tool remains for refinements.

**KB gap**: `kb_gap` is true when the playbook has `search_articles` and neither the automatic search nor any search the model ran found an article. It is computed in code (`Responder#handle`), never by the model. On a gap the turn-2 request carries a "no guide matched" directive and the collector's handoff is forced (`KB_GAP_HANDOFF_REASON`), so the ticket goes to a person. The `handle` `AiRun` output stores `kb_gap` (Boolean) and `kb_queries` (Array, max 3 searched queries); there is no separate KB gap note any more: the same fact appears on the single `ai` note's `Help center:` line. Admins see a "KB gap" badge on that run in the AI activity panel and in the run viewer, with a "Create article" link to `new_adminit_article_path(title:, category:)` (the locale comes from the `:locale` path scope, so the admin UI language is kept; `Adminit::ArticlesController#new` reads only `title`, `category` and `locale`, ignores invalid category/locale and truncates the title to 150 chars). Playbooks without `search_articles` never report a gap; `triage_only` playbooks still compute it for the run output.

**Search fallback**: `Support::Article.search` runs the AND `websearch_to_tsquery('simple', ...)` first and, when it finds nothing, retries as an OR of prefix terms (`to_tsquery`, terms of 3+ chars, max 8, sanitized) with a minimum rank. The AI `search_articles` tool does not filter by category (the AI's classification can be wrong); it searches the user's language first, then any locale.

**Admin note format**: ONE `ai` note per AI pass. `Support::Ai::Handle` writes the model's findings (1-2 factual English sentences, at most 40 words: what the user wants plus anything found with the tools; no next step, recommendation, or guesses about features, policies or causes; truncated at 1,200 chars) followed by a deterministic line, `Help center: <attached article titles>` or `Help center: no article answered this.`, and sets `context.note_written`. When `note_written` is set, `Finalize` skips the `HandoffNote` summary (no second note, no extra LLM call); otherwise (follow-up pass via `ProcessReply`, the user's "Talk to a human" button, or no `investigate_note` capability) the summary note is written, under the same constraints (at most 50 words, no judging earlier replies, no next step).

**Fixed handoff reply**: whenever a pass ends in a handoff (request_human, KB gap, triage escalate, max turns), the user message is the localized `support.ai.handoff_message` template (locale from the triage language, else `I18n.locale`), never the model's reply: "We're looking into this. I've passed your request to a teammate on our support team, and they'll follow up here." `triage_only` playbooks still post no message. `Fallback` uses the same key. `GROUNDING` also forbids stating that the product has or lacks a feature unless an article says so.

**Adding a capability**:
1. Register it in `SupportAi::Capabilities.install` with the right `kind`, `steps` and `default`
2. If it is a tool, add `SupportAi::Tools::<Name>` (inherit `Tools::Base`, scope queries to the requester, return minimal fields)
3. Add `support.ai.capabilities.<key>` label/hint translations in en and es (see existing keys)
4. Add specs: registry/tool spec, and a Responder or workflow example that uses it

**Stubbing the LLM in specs**: never hit the network.
- Workflow, job and interactor specs: `spec/support/support_ai_workflow_helpers.rb` — `stub_responder(triage: ai_result(triage_output), respond: ai_result(respond_output), summarize: ...)` replaces `SupportAi::Responder`; pass an exception class to simulate failure
- Responder/tool specs (`type: :service` or `:llm`): `spec/support/support_ai_llm_helpers.rb` — `stub_llm(text_body("..."), tool_call_body([[name, args]]))` stubs only the HTTP layer so the real tool loop runs; wrap in `with_openrouter_key`

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
