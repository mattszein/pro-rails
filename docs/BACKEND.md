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
