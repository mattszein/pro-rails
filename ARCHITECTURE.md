## Core Principles

1. **Right tool for the right complexity** - Use simple solutions for simple problems, patterns for complex ones
2. **Single source of truth** - Each rule lives in one place
3. **Explicit over implicit** - Code should be readable and intentions clear
4. **Defense in depth** - Multiple layers protect data integrity

---

## Tech Stack Summary

- **Background Jobs**: Solid Queue (database-backed, PostgreSQL)
- **WebSockets**: AnyCable (high-performance Action Cable replacement)
- **Cache**: Redis (not Solid Cache)
- **Configuration**: Anyway Config for typed configuration classes
- **Authentication**: Rodauth
- **Authorization**: ActionPolicy

---

## The Three Layers of Business Logic

| Layer | Responsibility | Question it Answers |
|-------|----------------|---------------------|
| **Model** | Data integrity, state transitions | "Is this data valid?" / "Is this transition legal?" |
| **Controller** | HTTP handling, authorization, UX guards | "Can this user attempt this action?" |
| **Interactor** | Workflow orchestration, side effects | "What sequence of things must happen?" |

### Request Flow

When an HTTP request arrives, it flows through these layers in order:

**Step 1: Controller receives the request.** The controller is responsible for handling HTTP concerns: parsing params, setting up instance variables, and determining the response format.

**Step 2: Authorization check.** The controller calls `authorize!` which delegates to ActionPolicy. The policy answers: "Does this user have permission to attempt this action?" This is purely about WHO, not about whether the action will succeed.

**Step 3: Route to appropriate handler.** Based on the action type:

- **For simple CRUD operations** (create, update, destroy with no side effects): The controller calls the model directly. The model's validations and callbacks enforce all business rules.

- **For workflow operations** (actions with multiple steps or side effects): The controller calls an interactor. The interactor orchestrates the workflow: calling model transitions, enqueuing jobs, sending notifications, etc.

**Step 4: Model enforces data integrity.** Whether called directly from the controller or through an interactor, the model always validates data integrity. Validations run on every save. Callbacks protect against invalid deletions. Transition methods enforce state machine rules.

**Step 5: Controller sends response.** Based on success or failure, the controller redirects, renders a template, or returns JSON.

---

## When to Use Each Pattern

### Standard Controller (Direct Model Calls)

Use for actions that:

- Are simple CRUD operations
- Have no side effects beyond the database
- Validations are handled entirely by the model

```ruby
def create
  @record = Model.new(params)
  if @record.save
    redirect_to @record
  else
    render :new
  end
end

def update
  if @record.update(params)
    redirect_to @record
  else
    render :edit
  end
end
```

### Interactors (Workflow Orchestration)

Use when an action:

- Spans multiple steps or state transitions
- Has side effects (jobs, notifications, external APIs)
- Must be callable from non-HTTP contexts (jobs, console)
- Represents a domain event, not just a CRUD mutation

The controller calls the interactor, which handles the workflow:

```ruby
def schedule
  result = Announcement::Schedule.call(announcement: @announcement)
  
  if result.success?
    redirect_to @announcement, notice: "Scheduled"
  else
    redirect_to @announcement, alert: result.error
  end
end
```

### Decision Framework

| Scenario | Pattern | Example |
|----------|---------|---------|
| Simple create/update/delete | Controller + Model | Creating a draft |
| State change + side effects | Interactor | Scheduling (update + enqueue job) |
| Multiple models affected | Interactor | Publishing (update + notifications) |
| External API call | Service Object | Payment processing |
| Complex query | Query Object | Dashboard statistics |

---

## Authentication (Rodauth)

We use Rodauth for authentication, configured in `app/misc/rodauth_main.rb` and `app/misc/rodauth_app.rb`.

### Key Features

- Email-based authentication with multi-phase login
- Account verification via email
- Password reset and change
- Email authentication (magic links)
- Remember me functionality
- Account closure

### Account Model

The `Account` model integrates with Rodauth and has three statuses:

| Status | Value | Description |
|--------|-------|-------------|
| `unverified` | 1 | Account created but email not verified |
| `verified` | 2 | Email verified, account active |
| `closed` | 3 | Account closed by user or admin |

### Accessing Current User

In controllers and views, access the authenticated user via:

```ruby
current_account  # Returns the Account record or nil
```

### Testing Authentication

In request and controller specs, use the login helpers:

```ruby
# In spec/rails_helper.rb, LoginHelpers are included

# Request specs
login_as(account)

# Or use Rodauth directly
rodauth.login(account)
```

---

## Authorization (ActionPolicy)

We use ActionPolicy for authorization, and we have a custom RBAC system for the admin part.

### Three-Layer Authorization

1. **Account-level gate** - `Account#adminit_access?` checks if role exists
2. **Controller-level gate** - `before_action :authorize_adminit_access`
3. **Policy-level checks** - `authorize!` per action/resource

### Policy Structure

```ruby
module Adminit
  class AnnouncementPolicy < ApplicationPolicy
    self.identifier = :"Adminit::AnnouncementPolicy"
    
    # All actions use default manage? rule
    # Define specific methods only if different logic needed
  end
end
```

The `identifier` is stored in the Permission model's `resource` column. Policies check if the user's role has a permission with that identifier.

### Controller Usage

```ruby
def show
  authorize! @announcement
end

def index
  @announcements = authorized_scope(Announcement.all)
end
```

### View Usage

```erb
<% if allowed_to?(:edit?, @announcement) %>
  <%= link_to "Edit", edit_path(@announcement) %>
<% end %>
```

### Policy vs Model Responsibilities

| Question | Where |
|----------|-------|
| "Can this USER do this?" | Policy |
| "Can this RECORD have this done?" | Model |

---

## Model Patterns

### Data Integrity Validations

Always enforced, regardless of how the record is saved:

```ruby
validates :title, presence: true
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :scheduled_at, presence: true, if: :scheduled?
```

### State-Based Validations

Prevent invalid state transitions:

```ruby
validate :scheduled_at_immutable_when_scheduled, on: :update
validate :cannot_update_when_published, on: :update

private

def cannot_update_when_published
  if status_was == "published"
    errors.add(:base, "Cannot update a published record")
  end
end
```

**Note:** Use `status_was` to check the **previous** value, allowing transitions to succeed.

### Query Methods

For UI visibility and controller guards. Pure queries, no side effects:

```ruby
def editable?
  !published?
end

def destroyable?
  draft?
end
```

### Transition Methods

For state changes. Called by interactors. Pure database operations, **no side effects**:

```ruby
def schedule!
  raise InvalidTransition, "Cannot schedule" if published?
  raise InvalidTransition, "Already scheduled" if scheduled?
  
  update!(status: :scheduled)
end

def publish!
  raise InvalidTransition, "Must be scheduled first" unless scheduled?
  
  update!(status: :published, published_at: Time.current)
end
```

**Critical Rule:** Transition methods must NEVER:

- Enqueue background jobs
- Send emails or notifications
- Call external APIs
- Trigger any side effects

This ensures models can be used safely in Console, Tests, and Seeds without unintended consequences.

### Destroy Protection

Use callbacks to prevent invalid deletions:

```ruby
before_destroy :ensure_destroyable

private

def ensure_destroyable
  unless draft?
    errors.add(:base, "Only drafts can be deleted")
    throw(:abort)
  end
end
```

### Custom Exceptions

Define domain-specific exceptions for transition failures:

```ruby
class Announcement < ApplicationRecord
  class InvalidTransition < StandardError; end
  
  def publish!
    raise InvalidTransition, "Already published" if published?
    # ...
  end
end
```

### Namespaced Domain Models

Use namespacing when you have multiple related models that form a domain:

```ruby
# app/models/support/ticket.rb
module Support
  class Ticket < ApplicationRecord
    has_one :conversation
    has_many :messages, through: :conversation
  end
end

# app/models/support/conversation.rb
module Support
  class Conversation < ApplicationRecord
    belongs_to :ticket
    has_many :messages
  end
end
```

**When to namespace:**

- Multiple models that belong together (Support::Ticket, Support::Conversation, Support::Message)
- Clear domain boundary exists
- Models share a table prefix (`support_tickets`, `support_conversations`)

**When NOT to namespace:**

- Single standalone model (Announcement)
- Model is used across multiple domains

---

## Interactor Patterns

We use the [interactor](https://github.com/collectiveidea/interactor) gem for workflow orchestration.

### Basic Structure

```ruby
module Announcement
  class Schedule
    include Interactor

    delegate :announcement, to: :context

    def call
      ActiveRecord::Base.transaction do
        announcement.schedule!
        enqueue_publish_job
      end
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
def call
  # business logic
rescue Model::InvalidTransition, ActiveRecord::RecordInvalid => e
  context.fail!(error: e.message)
end
# StandardError, NoMethodError, etc. → bubble to Sentry/Honeybadger
```

### Transactions

Wrap multiple database operations in a transaction:

```ruby
def call
  ActiveRecord::Base.transaction do
    record.transition!
    enqueue_job
  end
end
```

**Note:** Because we use Solid Queue (database-backed), the job enqueue is part of the same transaction. Both succeed or both rollback atomically.

### When to Use Organizer

Use `Interactor::Organizer` when:

- 4+ steps in the workflow
- Steps are reusable across different workflows
- Complex per-step rollback logic needed

For 2-3 steps, a single interactor with a transaction is simpler.

---

## Background Jobs

We use Solid Queue (Rails 8 default) for background jobs. Jobs are stored in PostgreSQL, not Redis.

### Job Structure

```ruby
class PublishAnnouncementJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(announcement_id, expected_scheduled_at)
    announcement = Announcement.find_by(id: announcement_id)

    # Idempotency guards
    return unless announcement
    return if announcement.scheduled_at.to_i != expected_scheduled_at
    return if announcement.published?

    result = Announcement::Publish.call(announcement: announcement)

    raise "Failed to publish: #{result.error}" if result.failure?
  end
end
```

### Idempotency Guards

Jobs should be safe to run multiple times:

| Guard | Purpose |
|-------|---------|
| Record exists | Handle deleted records |
| Timestamp matches | Detect stale jobs after reschedule |
| Already completed | Skip if already done |

### Safety Net Pattern

For critical jobs, add a recurring safety net that catches any records that failed to process. The primary job handles the happy path at the exact scheduled time. The safety net runs periodically to catch anything that slipped through due to failures, server restarts, or edge cases.

### Transaction Safety with Solid Queue

Because Solid Queue stores jobs in PostgreSQL, wrapping model updates and job enqueues in a transaction creates atomic operations. Both the model update and the job insert happen in the same database transaction, so both succeed or both rollback together.

**Note:** If migrating to Redis-based queues (Sidekiq), use `after_transaction_commit` to avoid race conditions where the job runs before the transaction commits.

### Recurring Jobs

Configure recurring jobs in `config/recurring.yml`:

```yaml
publish_overdue_announcements:
  class: PublishOverdueAnnouncementsJob
  schedule: "every 5 minutes"
```

---

## Turbo Streams & Real-time Updates

We use AnyCable for WebSocket connections, replacing the default Action Cable for better performance.

### When to Use `broadcasts_to` in Models

Use model-level broadcasting for **simple CRUD updates** where you want automatic real-time sync:

```ruby
class Support::Ticket < ApplicationRecord
  broadcasts_to ->(ticket) { "tickets" }
  broadcasts_to ->(ticket) { "admin_tickets" }
end
```

This automatically broadcasts on `after_create_commit`, `after_update_commit`, and `after_destroy_commit`.

**Good for:**

- Simple record changes (created, updated, destroyed)
- Updates that should always broadcast regardless of context
- Chat messages, comments, status changes

### When NOT to Use Model Broadcasting

Do NOT use model-level broadcasting when:

1. **The broadcast is conditional on business logic** - Use interactor instead
2. **The broadcast is part of a larger workflow** - Use interactor instead
3. **You need to broadcast to specific users** - Handle in interactor or controller
4. **The update involves sensitive notifications** - Handle explicitly in interactor

Example - Publishing an announcement should NOT auto-broadcast from model:

```ruby
# BAD - Model broadcasts on every update
class Announcement < ApplicationRecord
  broadcasts_to ->(a) { "announcements" }  # Don't do this
end

# GOOD - Interactor handles broadcasting explicitly
module Announcement
  class Publish
    include Interactor

    def call
      announcement.publish!
      broadcast_to_users
      deliver_notifications
    end

    private

    def broadcast_to_users
      Turbo::StreamsChannel.broadcast_append_to(
        "announcements",
        target: "announcements",
        partial: "announcements/announcement",
        locals: { announcement: announcement }
      )
    end
  end
end
```

### Summary: Model vs Interactor Broadcasting

| Scenario | Where to Broadcast |
|----------|-------------------|
| Simple CRUD sync | Model (`broadcasts_to`) |
| Workflow with notifications | Interactor |
| Conditional broadcasts | Interactor |
| User-specific broadcasts | Interactor or Controller |

---

## ViewComponent Architecture

We use ViewComponent for building reusable UI components.

### Directory Structure

Components live in `app/components/core/` with their corresponding CSS and JS files in the same directory:

```
app/components/core/
├── form/
│   ├── material_input_component.rb
│   ├── material_input_component.html.erb
│   ├── button_component.rb
│   └── button_component.html.erb
└── ...
```

### Custom Form Builder

All forms should use `CustomFormBuilder`, which renders ViewComponents automatically:

```erb
<%= form_with model: @announcement, builder: CustomFormBuilder do |form| %>
  <%= form.text_field :title %>
  <%= form.text_area :body %>
  <%= form.button "Save", theme: :primary %>
<% end %>
```

`CustomFormBuilder` is set as the default form builder in `ApplicationController`.

### Available Form Components

**Input Components:**

- `form.text_field`, `form.password_field`, `form.number_field` → MaterialInput
- `form.text_area` → TextArea
- `form.code(length: 6)` → Code input for verification

**State Components:**

- `form.toggle`, `form.check_box` → Toggle/Checkbox
- `form.select`, `form.multi_select` → Enhanced selects

**Action Components:**

- `form.button(theme: :primary, size: :md)` → Button
  - Themes: `:primary`, `:secondary`, `:create`, `:edit`, `:delete`, `:show`
  - Sizes: `:xs`, `:sm`, `:md`, `:lg`, `:xlg`, `:giant`

### Component Previews

Lookbook is available in development at `/lookbook` to preview and test components.

---

## Configuration

We use Anyway Config for typed configuration classes.

### Structure

```ruby
# config/configs/application_config.rb
class ApplicationConfig < Anyway::Config
  attr_config :app_name, :default_from_email
end

# config/configs/aws_config.rb
class AwsConfig < Anyway::Config
  attr_config :access_key_id, :secret_access_key, :region, :bucket
end
```

### Usage

```ruby
ApplicationConfig.new.app_name
AwsConfig.new.bucket
```

Configuration values are loaded from environment variables, credentials, or YAML files.

---

## Service Objects

Use for external API integrations and third-party services:

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

### Service Object vs Interactor

| Use Case | Pattern |
|----------|---------|
| External API calls | Service Object |
| Internal workflow orchestration | Interactor |
| Complex queries | Query Object |

---

## Notifications

We use [noticed](https://github.com/excid3/noticed) gem for notifications.

### Notifier Structure

```ruby
class AnnouncementNotifier < ApplicationNotifier
  deliver_by :action_cable, channel: "NotificationsChannel", if: :web_enabled?
  deliver_by :email, mailer: "AnnouncementMailer", if: :email_enabled?

  notification_methods do
    def message
      "New announcement: #{record.title}"
    end
  end
end
```

### Delivery from Interactor

Notifications are triggered from interactors, never from models. This keeps models focused on data integrity and makes notification logic explicit and testable.

---

## Testing Patterns

### Model Specs

Use Shoulda-Matchers for validation tests:

```ruby
RSpec.describe Announcement, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
  end

  describe "associations" do
    it { should belong_to(:author).class_name("Account") }
  end
end
```

### Request Specs

Use login helpers for authenticated requests:

```ruby
RSpec.describe "Announcements", type: :request do
  let(:account) { create(:account, :with_admin_role) }

  before { login_as(account) }

  describe "POST /adminit/announcements" do
    it "creates an announcement" do
      post adminit_announcements_path, params: { announcement: attributes }
      expect(response).to redirect_to(adminit_announcement_path(Announcement.last))
    end
  end
end
```

### Interactor Specs

Test interactors in isolation:

```ruby
RSpec.describe Announcement::Schedule, type: :interactor do
  let(:announcement) { create(:announcement, :draft, scheduled_at: 1.hour.from_now) }

  describe ".call" do
    context "with valid announcement" do
      it "succeeds" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_success
      end

      it "changes status to scheduled" do
        described_class.call(announcement: announcement)
        expect(announcement.reload).to be_scheduled
      end

      it "enqueues publish job" do
        expect {
          described_class.call(announcement: announcement)
        }.to have_enqueued_job(PublishAnnouncementJob)
      end
    end

    context "when already published" do
      let(:announcement) { create(:announcement, :published) }

      it "fails" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
        expect(result.error).to eq("Already published")
      end
    end
  end
end
```

### Policy Specs

Use ActionPolicy matchers:

```ruby
RSpec.describe Adminit::AnnouncementPolicy, type: :policy do
  let(:user) { create(:account, :with_admin_role) }
  let(:record) { create(:announcement) }

  describe_rule :manage? do
    succeed "when user has admin role"

    context "when user has no role" do
      let(:user) { create(:account) }
      it { is_expected.to be_forbidden }
    end
  end
end
```

---

## File Organization

Interactors are organized by domain in `app/interactors/{domain}/`. Each interactor is a single file named after the action it performs.

Jobs live in `app/jobs/` and are named after what they do, ending in `Job`.

Models live in `app/models/`. Namespaced models use subdirectories (e.g., `app/models/support/ticket.rb` for `Support::Ticket`).

Policies mirror the controller structure in `app/policies/`.

Service objects for external APIs live in `app/services/external_services/`.

Notifiers live in `app/notifiers/`.

Configuration classes live in `config/configs/`.

---

## Summary: Where Does Code Belong?

| Code Type | Location |
|-----------|----------|
| Data validations | Model |
| State transition rules | Model (transition methods) |
| State queries for UI | Model (query methods) |
| Destroy protection | Model (before_destroy callback) |
| Simple CRUD broadcasts | Model (broadcasts_to) |
| Authorization (WHO) | Policy |
| Workflow orchestration | Interactor |
| Side effects (jobs, emails) | Interactor |
| Complex broadcasts | Interactor |
| External API calls | Service Object |
| HTTP handling | Controller |
| UX guards (prevent invalid forms) | Controller |
| Typed configuration | Config class (Anyway Config) |
