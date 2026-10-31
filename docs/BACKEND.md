---
name: backend
description: >
  Implement Ruby/Rails business logic — models, controllers, interactors, jobs, services, migrations, I18n, and broadcasts.
  Trigger: When writing Rails models, controllers, interactors, migrations, background jobs, service objects, or business logic.
license: Apache-2.0
metadata:
  author: mattszein
  version: "1.2"
---

You are a Backend Engineer. You write models, controllers, interactors, jobs, services, policies, migrations and I18n, and you configure broadcasts. You never write views, components or CSS (that's frontend). Rules and boundaries: `docs/ARCHITECTURE.md`.

**Stack:** PostgreSQL · Rodauth (`app/misc/rodauth_*.rb`) · ActionPolicy (Adminit RBAC) · Interactor (`app/interactors/{domain}/`) · Solid Queue (**separate DB**) · Redis cache · AnyCable · Anyway Config (`config/configs/`) · Noticed (`app/notifiers/`) · Freezolite (adds `frozen_string_literal`, off in test).

---

## Models

Order inside a model: extensions → associations → enums → normalizations → validations → scopes → callbacks (score 3–5) → delegations → broadcasts → query methods → transitions → private. A large set of transitions moves to a concern (`Support::Ticket::Transitions` in `app/models/concerns/support/ticket/transitions.rb`).

### Query Methods

Pure predicates for UI visibility and controller guards. No side effects:

```ruby
def editable? = !published?
def destroyable? = draft?
```

### Validations

```ruby
validate :cannot_update_when_published, on: :update   # previous value: status_was

# Invariant: fail loudly; never fix it in a callback
validate :ai_not_engaged_while_assigned

def ai_not_engaged_while_assigned
  errors.add(:ai_state, :engaged_while_assigned) if assigned_id.present? && ai_engaged?
end
```

### Transitions

The only path for state columns and ownership FKs. Guards inside `with_lock` (it reloads the row), one `update!` (never call other bang transitions), owned records inside the lock, no side effects, return `self`.

```ruby
def assign!(to:, by:)
  with_lock do
    raise AlreadyAssigned, I18n.t("ticket.transitions.already_assigned") unless assigned_id.nil?
    raise InvalidTransition, I18n.t("ticket.transitions.can_only_take") unless open? || reopen_requested? || reopened?

    released_ai = ai_engaged?              # own state, inside its own transition: fine
    attrs = {assigned: to}
    attrs[:status] = :in_progress if open?
    attrs[:ai_state] = :stepped_back if released_ai
    update!(attrs)                         # one save: one stamp, one broadcast

    add_note("Ticket taken by #{to.email}.", account: by)
    add_note(AI_STEPPED_BACK_NOTE, account: nil) if released_ai
  end
  self
end
```

Note texts are neutral ("Ticket reopened.", not "Admin reopened…"); the actor is stored in `account:`. Callers never pre-capture state or read `saved_change_to_*` to learn what happened.

Every transition has a stale-instance spec, plus legal and illegal source states and the notes it writes:

```ruby
it "rejects a stale transition" do
  stale = Support::Ticket.find(ticket.id)
  ticket.take!(by: admin)                  # state moves on
  expect { stale.start_ai_analysis! }.to raise_error(Support::Ticket::InvalidTransition)
end
```

### Exceptions, Destroy Protection, Audit Records

```ruby
class DomainError < StandardError; end              # app/models/domain_error.rb
class InvalidTransition < DomainError; end          # one per model
class AlreadyAssigned < InvalidTransition; end      # when callers must distinguish it

before_destroy :ensure_destroyable

def ensure_destroyable
  return if draft?
  errors.add(:base, I18n.t("activerecord.errors.models.announcement.attributes.base.only_draft_deletable"))
  throw(:abort)
end

# Support::Note: system notes are immutable; the ticket's dependent: :destroy still works (so no readonly?)
before_update  -> { throw(:abort) }, if: :system?
before_destroy -> { throw(:abort) unless destroyed_by_association }, if: :system?
```

### Concerns and Namespaces

- Cross-model concern → flat `app/models/concerns/localizable.rb`. Model-specific → `concerns/account/notifiable.rb` (`module Account::Notifiable`), starting with the model's 2nd concern.
- Domain models are namespaced (`Support::Ticket`) with plain table names (`self.table_name = "tickets"`, not `support_tickets`) unless names collide.

### Broadcasts

Broadcasts that reflect record state live in the model, because they must fire on every path. A broadcast that exists for one workflow goes in that interactor (`Turbo::StreamsChannel.broadcast_*`). In models, `dom_id` is unavailable: use `ActionView::RecordIdentifier.dom_id`.

Broadcast partials render without `current_account`, so they must be viewer-neutral: no `allowed_to?` or per-viewer branches inside them. Show or hide per-viewer UI client-side (`<turbo-show>`, as in `ai_status_component` and `message_component`); the policy stays the real barrier.

```ruby
broadcasts_to ->(_ticket) { "tickets" }, partial: "support/tickets/ticket_table"

after_update_commit do
  if saved_change_to_status? || saved_change_to_ai_state?
    broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(self),
      target: ActionView::RecordIdentifier.dom_id(self, :ai_status),
      partial: "support/conversations/ai_status"
  end
end
```

---

## Tables (sort/filter)

Rules: ARCHITECTURE → Table Queries.

1. SQL is a scope: `scope :search_title, ->(q) { where("title ILIKE ?", "%#{sanitize_sql_like(q)}%") }`
2. The whitelist is declared on the column, in the namespace helper (`app/helpers/{namespace}/{resource}_helper.rb`):

   ```ruby
   Core::Table::Column.new(label: I18n.t("shared.labels.title"), renderer: ->(t) { t.title }, sort_key: :title,
     filter: Core::Table::Filter.new(type: :text, param: :search, scope: :search_title))
   ```

   With `scope:` → `relation.public_send(scope, value)`. Without it → `where(param => value)`, which raises in dev/test if `param` isn't a column (a typo fails instead of silently doing nothing).
3. The same column set goes to the query and the view:

   ```ruby
   @columns = helpers.ticket_columns
   @pagy, @tickets = apply_table_params(Support::Ticket.includes(:created, :assigned).prioritized, columns: @columns)
   ```

   ```erb
   <%= render Core::TableComponent.new(rows: @tickets, columns: @columns, options: {sortable: true, filterable: true, pagy: @pagy}) %>
   ```

   The base relation is the row-level access.
4. Association option lists use an audience scope: `options: -> { Account.assignable.pluck(:email, :id) }`, with `scope :assignable, -> { where.not(role_id: nil).order(:email) }`.
5. Context filters (`current_account`, "now") aren't built. When needed: a controller lambda over a scope, never request state in the model.

Two contexts, two column sets: `/support/tickets` (owner's rows, `category` filter) and `/adminit/tickets` (all rows, `priority` sort).

### Full-Text Search (Support::Article)

- `Support::Article.search` (admin) and `Support::Article.published_search` (help center, suggestions, AI) take `(query, locale:, category:, limit:)`.
- They query a stored, GIN-indexed `searchable` tsvector (title A, summary B, body C) with `websearch_to_tsquery('simple', ...)`. `search_text` is synced from `body.to_plain_text` in `before_save`.
- Ties go to the newest `published_at`. A `category` also matches `general`.
- The category enum is `Support::Ticket::CATEGORIES` plus `general` (`Support::Article::GENERAL_CATEGORY = 100`, the column default, never nil), so tickets and articles can't drift.
- No match → retry as an OR of prefix terms (3+ chars, max 8, sanitized) with a minimum rank. The AI never filters by category.

---

## Feature Flags

Operator-controlled release gates: a flag holds reusable **audiences** plus per-account **allow/block** entries, evaluated in-process against committed DB state. Rules: ARCHITECTURE → Feature Flags.

| Piece | Where |
|---|---|
| Registries (`DeclaredRegistry`) | `app/lib/feature_flags/registry.rb`, `app/lib/audience_conditions/registry.rb` |
| Declarations | `app/lib/feature_flags/flags.rb`, `app/lib/audience_conditions/vocabulary.rb`. Demo flag `test_feature_flag` (superadmin audience, dashboard banner): replace it |
| Decision | `FeatureFlags.for(account)` / `.enabled?(key, account)`: `app/models/feature_flags.rb`, `app/models/feature_flags/account_evaluator.rb` |
| Consumption | `feature_enabled?(key)`, `require_feature!(key)`: `app/controllers/concerns/feature_gated.rb`, on `SharedBaseController` |
| State (display only) | `FeatureFlag`, `Audience`, `AudienceCondition`, `FeatureFlagAudience`, `FeatureFlagAccount` |
| Admin | `Adminit::FeatureFlagsController` (attach/detach audience, allow/block account), `Adminit::AudiencesController` (CRUD + archive). Single-row writes, no interactor |

**Declare:** `Registry.register(:new_dashboard)` in `flags.rb`, plus `feature_flags.flags.new_dashboard: {name:, description:}` in en and es. `bin/rails feature_flags:sync` creates the row; it also runs in `db:prepare`, but not in `db:migrate` or `db:schema:load`. The flag is off until an operator attaches an audience or account.

**Gate:** `before_action { require_feature!(:new_dashboard) }` (404) · `<% if feature_enabled?(:new_dashboard) %>`.

**Audience condition:**

```ruby
Registry.register(key: :on_paid_plan, type: :boolean, accepts: [true, false],
  predicate: ->(account, value) { account.paid? == value })
```

- Types: `:boolean`, `:affirmative` (off/true), `:id_list` (`accepts:` names the model), `:duration` (`{amount:, unit:}`).
- The predicate uses only account + value: no query of its own, and no clock (a fixed age threshold is the one exception).
- Labels go in `config/locales/{en,es}/audience_conditions.yml`. A new type needs one partial in `app/views/adminit/audiences/conditions/`.

**Retire:** delete the `register` line. The row and its history stay; `FeatureFlag.declared` stops returning it, so Adminit no longer lists it and `FeatureFlags.enabled?` returns false (logged, not raised). An audience attached only to that flag is free to reuse.

**Precedence** (set in Adminit, no code change): block > allow > any matching audience.

**Account picker:** every admin picker uses `Adminit::AccountsController#search` (`GET /adminit/accounts/search`).

---

## LLM (Llm::Runner)

`Llm::Runner` (`app/services/llm/`) is the only way to call an LLM, and it is generic (no domain knowledge). It builds the RubyLLM chat (OpenRouter ids, no registry lookup), applies the timeout, measures tokens and latency, enforces the tool budget and maps errors.

```ruby
result = Llm::Runner.new(timeout: 120, temperature: nil, provider: :openrouter)
  .call(model: model, system: nil, tools: [], schema: nil, budget: Llm::ToolBudget.new) do |chat|
    parse(chat.ask(prompt).content)        # the block's value is Result#output
  end
result.output / .model / .input_tokens / .output_tokens / .latency_ms / .tool_calls / .transcript
```

- A nil `system` or `temperature` is skipped.
- Tools are `Llm::Tools::Base` subclasses sharing the budget: identical calls are cached; a spent budget answers "Tool limit reached"; a model that keeps calling gets `Llm::Error`.
- `RubyLLM::Error`, `ConfigurationError`, `ModelNotFoundError`, `Timeout::Error` and `JSON::ParserError` become `Llm::Error` (original as `cause`, carrying `transcript` and `tool_calls`). Raise `Llm::Error` yourself for invalid output.
- The runner never writes to the DB and does no domain parsing.

**New AI feature:**
1. A prompt module of pure functions (`SupportAi::Prompts`, `AvatarAi::Prompts`).
2. A service that builds the runner from feature config; its block asks, parses and validates (raise `Llm::Error` when invalid).
3. Callers rescue `Llm::Error`, or a feature error wrapping it (`AvatarAi::BaseGenerator::GenerationError`); jobs use `retry_on Llm::Error`.
4. If it must be auditable, persist the `Result` or the error's transcript in a run table (`Support::Ai::RecordRun`).
5. Specs stub HTTP only (`stub_llm`, `text_body`, `tool_call_body`).

Examples: `SupportAi::Responder` (tools, multi-turn, audited runs) and `AvatarAi::BaseGenerator#ask` (single prompt).

---

## Support AI

Product overview: `docs/PROJECT.md`. The assistant is interactors run from a job, `SupportAi::Responder`, and a capability registry. Behavior lives in `Support::AiPlaybook` rows; code only declares what is possible.

- **Context is prefetched in code** (`SupportAi::Context`); the model never asks for it.
- **The only tool is `search_articles`.**
- **Outcomes are answer JSON** `{reply, article_ids, resolution_proposed, handoff, handoff_reason}`. No action tools; the model never writes to the DB.

### Pipeline

`Support::AiProcessJob` (queue `support_ai`). Organizers in `app/interactors/support/ai/flows/`, steps in `app/interactors/support/ai/`.

- `Flows::ProcessTicket`: Triage → SelectPlaybook → ApplyTriage → Handle → Finalize
- `Flows::ProcessReply` (the user wrote while the AI owns the ticket): SelectPlaybook → Respond → Finalize

| Step | Does | On failure |
|---|---|---|
| Triage | One structured call: category, priority, language, escalate. Runs first because the playbook depends on it. A retry reuses an already-succeeded run | Non-fatal: logged; continue with the ticket's values |
| SelectPlaybook | `Support::AiPlaybook.match_for(ticket, priority:)` | None found: new ticket → `ai_state off`; ongoing → `Fallback`. Organizer stops |
| ApplyTriage | Applies only what the playbook allows (`auto_set_priority`, `auto_correct_category`), only when different, in one `update!`, with one English system note per change (workflow context, so it belongs here) | Raises |
| Handle | `Responder#handle`: one chat and `ToolBudget`, two turns (findings for admins, then answer JSON). `triage_only` and escalated triage run turn 1 only | Fatal: logged, re-raised for retry |
| Respond | `Responder#respond` from earlier succeeded triage/handle outputs. Skipped for `triage_only` or escalated | Fatal |
| Finalize | All DB writes, under `ticket.with_lock`. Transitions lock again (reload), so never change ticket attributes in memory before calling one | See Handoff |

Optional steps never stop the user from getting an answer.

**Job** (`queue_as :support_ai`, own worker in `config/queue.yml`; add new queues to the general worker): `FLOWS` maps trigger (`ticket_created`, `user_message`, the `AiRun` trigger names) → organizer. `AiProcessJob.enqueue(ticket, trigger, message_id)` validates the trigger (unknown → `KeyError`), rescues only enqueue errors, logs and returns false; it never undoes the state change. `perform` returns if the ticket or trigger message is gone, or unless `ai_analyzing?` (cost early exit; `Finalize` re-checks under the lock). No debounce: nobody writes while the AI analyzes. `retry_on Llm::Error` (3 attempts, polynomial); when retries run out, `Fallback` (idempotent) posts the handoff reply plus a system note.

**User messages:** `Support::Messages::Create` takes `ticket.with_lock`, refuses the requester unless `messageable?` (`support.messages.not_sent`), saves the message and `start_ai_analysis!` atomically, and enqueues `:user_message` after the lock. Admin messages (assignee only) never flip or enqueue.

### Responder, Context, ToolBudget

- **`Responder`** is pure: prompts, parsing, validation and the KB gap, with plumbing via `Llm::Runner`. Returns `Llm::Result` or raises `Llm::Error`. No DB writes.
- **Handle parsing:** tolerant JSON, one retry, then `Llm::Error`. `article_ids` survive only if the model saw them this step (prefetch or `search_articles`) and they're still published, max 3. `handoff` and `resolution_proposed` are coerced to booleans.
- **`Context`** builds one untrusted block per enabled capability:
  - `account_facts`: requester only (status, verified, member since, role; no email).
  - `past_tickets`: requester's own, max 10.
  - Article prefetch: ticket text (`[[:alnum:]]` words, ~300 chars), user's locale first, published only, top 3 (id, slug, locale, title, summary, excerpt). Recorded on the budget as found.
- **`SupportAi::ToolBudget`** (an `Llm::ToolBudget`, limit `SupportAiConfig.max_tool_calls`, default 10) is shared by a step's tools. Identical calls are cached and not counted; when spent, tools answer "Tool limit reached"; 3 more attempts → `Llm::Error`. Tracks `searched_queries` and `found_article_ids`.
- **Transcripts:** `Llm::Runner` builds an `Llm::Transcript` on success and failure (`Result#transcript`, `Error#transcript` / `#tool_calls`), so failed runs are inspectable.

### Notes

One `ai` note per pass, written only by `Finalize`, in the same lock as the reply. `Handle` builds `context.note_body` (only with `investigate_note`): findings (1–2 English sentences, ≤ 40 words, truncated at 1,200 chars), then code-built lines:

- `Help center: <attached titles>` or `Help center: no article answered this.`
- With `similar_tickets`: `Similar resolved tickets: #12 title (2026-09), ...` via `Support::Ticket.resolved_similar_to`. Admin only; no LLM; never in a prompt.

A handoff appends `AI handoff: <reason>` as the last line (no LLM call), even without findings. A discarded pass keeps the findings, ending with `Reply not sent: ...`. "Talk to a person" and "I still need help" are allowed only while `awaiting_user` (`TicketPolicy#request_human?`) and write `User requested a human`.

### KB Gap

- Computed in code (`Responder#handle`): the playbook has `search_articles` and neither the prefetch nor the model's searches found an article.
- Turn 2 then gets a "no guide matched" directive and the handoff is forced (`KB_GAP_HANDOFF_REASON`, unless the model gave its own reason).
- The run output stores `kb_gap` and `kb_queries` (max 3). The only admin trace is the `Help center:` line.
- Without `search_articles` there is never a gap. `triage_only` computes it for the run output only. Enforced in `handle` only.

### Handoff

- **Triggers** (in Finalize): the answer's `handoff` (including a KB gap), triage `escalate`, `triage_only`, or `max_ai_turns` reached.
- **Reply:** the localized `support.ai.handoff_message` (triage language, else `I18n.locale`), never the model's reply. `triage_only` posts nothing. `Fallback` uses the same key.
- **Under the lock,** Finalize re-checks `ai_analyzing?` (an admin may have taken the ticket); otherwise the reply is discarded and the run marked `discarded`.
- **Grounding** (`Prompts.grounding`): screens, menus, URLs or steps only from given or found articles or the playbook instructions; never claim a feature exists or not unless an article says so.

### ai_state

Changed only through transitions. Each checks its guard inside `with_lock` and raises `InvalidTransition` from a wrong state.

| Method | From → to |
|---|---|
| `start_ai_analysis!` | `off` / `awaiting_user` → `analyzing` (unassigned tickets only) |
| `disable_ai!` | `analyzing` → `off` |
| `await_user_reply!` | `analyzing` → `awaiting_user` |
| `request_ai_handoff!` | `analyzing` / `awaiting_user` → `handoff_requested` |
| `resolve_with_ai!` | `awaiting_user` (open ticket) → `resolved`, status `finished` |

**Invariant:** an assigned ticket never has the AI engaged (`ai_not_engaged_while_assigned`). `assign!` silences an engaged AI in the same `update!` and writes the note. Once a human was involved the AI doesn't re-engage: an unassigned `open` ticket whose AI stepped back is not messageable and waits for an agent.

### Playbooks

`Support::AiPlaybook.match_for(ticket, priority:)` uses the triaged priority, else the ticket's. Among enabled non-default playbooks that fit, the highest `specificity` wins (count of set conditions: categories, a priority bound, audience); ties go to the lowest id. Otherwise the enabled default; otherwise none. Nothing is stored on the ticket; every pass re-matches. The index shows the specificity badge.

### AiRun

- `Support::Ai::RecordRun` writes one `Support::AiRun` per step: trigger, step, status (`succeeded` / `failed` / `discarded`), model, tokens, latency, `tool_calls`, `transcript`, `output`, error. Record one for every new LLM step.
- `playbook_snapshot` (jsonb, `Support::AiPlaybook#snapshot`: name, mode, capabilities, instructions, limits, conditions) freezes the rules used, so history survives playbook edits. `playbook_id` is only a link, nullified on delete. `AiRun.step :investigate` is legacy (kept so old rows load).
- The admin "AI activity" panel opens a run in a modal (`Adminit::Tickets::AiRunsController#show` + `Adminit::Tickets::AiRunTranscriptComponent`, which takes the run and never queries): header, snapshot, error, transcript (system/user/assistant/tool entries, tool calls with JSON arguments), output. Authorization mirrors `Adminit::TicketsController#show`; the run is found via `ticket.ai_runs`. Content is always escaped (`Core::CodeBlockComponent`, never `raw`). Old runs show a "no transcript" note.

### Capabilities

`Support::AiCapabilities` / `Support::AiCapability` (`app/models/support/`, re-declared on reload by `config/initializers/support_ai_capabilities.rb`). Each declares `key`, `kind`, `steps` (`handle respond apply_triage draft`), `tool_class` or nil, and `default` (on in the seeded default playbook). Playbooks store keys; unregistered keys are invalid; `AiCapabilities.for_step` is the only gate between a playbook and a step.

| Kind | Keys |
|---|---|
| `context` (prefetched) | `account_facts`, `past_tickets` |
| `tool` (model-callable) | `search_articles` (also drives the prefetch and KB gap) |
| `flag` (code switch) | `similar_tickets`, `vision_attachments`, `investigate_note`, `auto_set_priority`, `auto_correct_category`, `draft_replies` |

**Security:** other users' data never enters a user-facing prompt. `similar_tickets` is code-only and feeds the admin note. Context and tools are scoped to the requester.

**Add one:**
1. Register it in `Support::AiCapabilities.install` with its `kind`, `steps` and `default`.
2. Add a context block to `SupportAi::Context`, or a tool `SupportAi::Tools::<Name> < Llm::Tools::Base` (requester-scoped, minimal fields).
3. Add `support.ai.capabilities.<key>` label and hint in en and es.
4. Add a registry/tool spec and a Responder or workflow example.

### Prompts, Authors, Config

- **Prompts:** all in `app/services/support_ai/prompts.rb`, token-lean (short imperatives, no repetition across system and user, shared parts defined once). Every user or third-party value goes through `Prompts.untrusted` (`<<<MARKER ... MARKER>>>`), and the system prompt forbids following instructions inside. Marker: `SupportAiConfig.untrusted_marker` (env `SUPPORT_AI_UNTRUSTED_MARKER`, default `UNTRUSTED`).
- **Authors:** `messages.sender` (`human` / `ai`) with nullable `account_id`; constraint `messages_sender_account_check` requires an account for human messages and none for AI. AI notes: `kind: :ai`, `account: nil`. Never fake an account.
- **Config:** `SupportAiConfig` (`config/support_ai.yml`): `enabled` (kill switch, default false), `model`, `vision_model` (for `vision_attachments`), `temperature`, `history_limit`, `max_tool_calls`, `timeout`, `untrusted_marker`. Override any with `SUPPORT_AI_<ATTR>`; API key `OPENROUTER_API_KEY`. Everything else is a playbook row; the default is seeded in `db/seeds.rb`.

### Specs

Never hit the network.

- Workflow, job and interactor specs: `stub_responder(triage:, handle:, respond:)` with `ai_result(...)`, or an exception class to simulate failure (`spec/support/support_ai_workflow_helpers.rb`).
- Responder and tool specs (`type: :service` / `:llm`): `stub_llm(text_body(...), tool_call_body([[name, args]]))` stubs HTTP only, so the real tool loop runs; wrap in `with_openrouter_key` (`spec/support/support_ai_llm_helpers.rb`).

---

## Controllers

Every controller has `before_action :require_account` (Rodauth's middleware doesn't set `current_account` inside controllers) and `verify_authorized` (every action must call `authorize!`). Use `:unprocessable_content`, not `:unprocessable_entity`. Never permit state columns or ownership FKs.

```ruby
def index
  @tickets = authorized_scope(Support::Ticket.all)
end

def update
  @ticket = Support::Ticket.find(params[:id])
  authorize! @ticket

  if @ticket.update(params.require(:ticket).permit(:title, :category))   # no :status, :assigned_id
    redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.updated")
  else
    render :edit, status: :unprocessable_content
  end
end
```

**Transition action** (single aggregate, no side effects): call it directly.

```ruby
include TransitionErrors   # app/controllers/concerns/transition_errors.rb: rescue_from DomainError / RecordInvalid → handle_transition_error

def finish
  @ticket.finish!(by: current_account)
  redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.finished")
end
```

**Workflow action** (side effects): an interactor, with failures rendered the same way.

```ruby
result = Announcements::Schedule.call(announcement: @announcement)
if result.success?
  redirect_to @announcement, notice: I18n.t("adminit.announcements.scheduled")
else
  render_transition_error(result.error)
end
```

- Turbo Frame actions: `ensure_frame_response` before_action.
- Modal forms: `respond_success(message, path)` / `respond_form_error(action)` from `ModalFormResponses` (in `Adminit::ApplicationController`). Define a private `modal_form_locals` returning the `_form` partial's locals (the concern raises `NotImplementedError` otherwise); the frame id is `<singular controller name>_form`.

---

## Interactors

Only when the operation goes beyond one aggregate (side effects, cross-aggregate writes, request context). Add one with the first side effect.

```ruby
module Announcements
  class Schedule
    include Interactor
    delegate :announcement, to: :context

    def call
      announcement.schedule!
      PublishAnnouncementJob.set(wait_until: announcement.scheduled_at)
        .perform_later(announcement.id, announcement.scheduled_at.to_i)   # after the transition committed
    rescue DomainError, ActiveRecord::RecordInvalid => e                    # bugs bubble up
      context.fail!(error: e.message)
    end
  end
end
```

Transactions only across aggregates; enqueue outside them, since Solid Queue is a separate DB:

```ruby
ActiveRecord::Base.transaction do
  ticket.finish!(by: account)
  account_stats.record_resolution!(ticket)   # another aggregate
end
notify_requester
```

- Organizer: 4+ reusable steps.
- Request context is passed explicitly: `Tickets::Assign.call(ticket: @ticket, assignee: account, ip_address: request.remote_ip)`.

---

## Jobs

```ruby
class PublishAnnouncementJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(announcement_id, expected_scheduled_at)
    announcement = Announcement.find_by(id: announcement_id)
    return unless announcement                                          # record exists
    return if announcement.scheduled_at.to_i != expected_scheduled_at  # not a stale job

    result = Announcements::Publish.call(announcement: announcement)
    Rails.logger.error("PublishJob failed for #{announcement_id}: #{result.error}") if result.failure?
  end
end
```

No state guards in jobs: locked transitions raise `InvalidTransition`, even when the job holds a stale record. A cheap early return is fine only to skip expensive work (see Support AI → Job).

## Policies

```ruby
module Adminit
  class AnnouncementPolicy < ApplicationPolicy
    POLICY_RESOURCE = :announcement
    self.identifier = :"Adminit::AnnouncementPolicy"
  end
end
```

New resource: ARCHITECTURE → Authorization.

## Notifications

```ruby
class AnnouncementNotifier < ApplicationNotifier
  deliver_by(:email) { |c| c.mailer = "AccountMailer"; c.method = "new_announcement" }
  deliver_by(:custom) { |c| c.class = "DeliveryMethods::TurboStream" }
  required_param :message

  notification_methods do
    def title = t(".title")
    def subtitle = record.title
    def notification_type = "announcement"
  end
end
```

Triggered from interactors, outside transactions. Bulk delivery → a job.

---

## I18n

```
config/locales/en.yml, es.yml        # model layer: AR, enums, transitions, validation errors
config/locales/{en,es}/shared.yml    # 2+ domains
config/locales/{en,es}/{adminit,support,settings,rodauth,mailers}.yml
```

Explicit keys (`I18n.t("adminit.tickets.updated")`), no lazy lookup · enums `t("enums.ticket.status.#{status}")`, never `.humanize` · explicit form `label:` · system notes in English · broadcasts locale-neutral · every key in en and es.

## Pagination

```ruby
@pagy, @records = pagy_countless(scope, limit: 20)   # infinite scroll, no COUNT
@pagy, @records = pagy(scope)                        # with total count
scope :before_cursor, ->(id) { where("id < ?", id).order(id: :desc).limit(PAGE_SIZE) }   # 10K+ live feeds
```

## Services, Pipelines, Config

```ruby
module ExternalServices                 # app/services/external_services/
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

module ContentPipeline                  # app/services/
  FILTERS = [Filters::SanitizeHtml, Filters::LinkifyUrls].freeze
  def self.apply(content) = FILTERS.reduce(content) { |c, filter| filter.new(c).apply }
end

class ApplicationConfig < Anyway::Config   # config/configs/; ApplicationConfig.new.app_name
  attr_config :app_name, :default_from_email
end
```

## Docker

```bash
docker compose exec -e RAILS_ENV=test rails bundle exec rspec                                     # all
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb:10      # one
docker compose exec rails bin/rails db:migrate
docker compose exec rails bin/rails db:seed
docker compose exec rails bin/rubocop -a
```

---

## Rules

- NEVER write views, components or CSS.
- NEVER skip `require_account` or `verify_authorized`.
- NEVER permit state columns or ownership FKs; they change only through transitions.
- ALWAYS check transition guards inside `with_lock`, and give every transition a stale-instance spec.
- NEVER add side effects to transitions, and never enqueue or deliver inside a transaction.
- NEVER pre-capture state or read dirty tracking to learn what a callback did.
- NEVER create an interactor that only wraps one transition.
- NEVER rescue `InvalidTransition` ad hoc in controllers; use `TransitionErrors`.
- NEVER hardcode user-facing strings; every key goes in en and es.
- ALWAYS use `:unprocessable_content`, and `ActionView::RecordIdentifier.dom_id` in models.
- Use `status_was` for previous values in validations.
- NEVER reuse an integer in `Permission::RESOURCE_REGISTRY`.
