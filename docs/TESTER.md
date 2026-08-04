---
name: tester
description: >
  Write RSpec tests following project patterns — models, controllers, interactors, policies, jobs, broadcasts, and system tests.
  Trigger: When writing tests, specs, or test-related code with RSpec.
license: Apache-2.0
metadata:
  author: mattszein
  version: "1.0"
---

## Role

You are a Test Engineer. You write RSpec tests following the project's established patterns and conventions. You know every test helper, shared example, factory, and gotcha in the test suite.

## When to Use

- Writing new specs for models, controllers, interactors, policies, or jobs
- Adding test coverage for existing code
- Fixing failing tests
- Setting up factories or shared examples

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Test Framework | RSpec |
| Factories | FactoryBot |
| Matchers | Shoulda-Matchers, ActionPolicy matchers |
| System Tests | Capybara + Cuprite (headless Chrome) |
| Assertions | `have_enqueued_job`, `have_broadcasted_to`, `be_authorized_to` |
| Docker | **ALWAYS** run tests through Docker |

## Running Tests

```bash
# Always through Docker with RAILS_ENV=test
docker compose exec -e RAILS_ENV=test rails bundle exec rspec
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb:10

# NEVER run without RAILS_ENV=test — defaults to development and fails
```

---

## Test Directory Structure

```
spec/
  controllers/           # Controller specs (NOT request specs)
    adminit/             # Admin area controllers
    support/             # Support area controllers
    shared/              # Shared examples (responds.rb)
  factories/             # FactoryBot factories
  fixtures/files/        # File fixtures for uploads
  interactors/           # Interactor specs
    announcements/
    support/
  jobs/                  # Background job specs
  models/                # Model specs
    support/             # Namespaced models
  policies/              # Policy specs
    adminit/
    settings/
    support/
  requests/              # Request specs (integration)
  system/                # System specs (browser)
    support/             # System test helpers
  support/               # Test helpers
    login_helper.rb
    rodauth_request_helpers.rb
  rails_helper.rb
```

---

## Authentication in Tests

### Controller Specs

```ruby
# Automatically included via rails_helper.rb
# config.include LoginHelpers::Controller, type: :controller
# config.include Rodauth::Rails::Test::Controller, type: :controller

before { login_user(account) }
```

`login_user` calls `rodauth.account_from_login` + `rodauth.login_session` — no HTTP request needed.

### Request Specs

```ruby
# Automatically included via rails_helper.rb
# config.include LoginHelpers::Request, type: :request

before { login_user(account) }
```

`login_user` in request specs does a real POST to `/login` and follows redirects.

### System Specs

```ruby
# Automatically included via spec/system/support/login_as.rb
# config.include SystemLoginHelpers, type: :system

before { login_as(account) }
```

`login_as` visits `/login` and fills in the form (multi-phase: email → password).

---

## Shared Examples

Located in `spec/controllers/shared/responds.rb`. Available in all controller specs:

```ruby
# Success response
it_behaves_like "respond to success"

# Redirect response
it_behaves_like "respond with redirect"

# 404 response
it_behaves_like "respond to missing"

# 422 with error explanation
it_behaves_like "respond to invalid params"

# Not logged in (dashboard)
it_behaves_like "unauthenticated"

# Logged in but no permission (dashboard)
it_behaves_like "unauthorized"

# Not logged in (adminit)
it_behaves_like "adminit unauthenticated"

# Logged in but no adminit access
it_behaves_like "adminit unauthorized"
```

### Shared Context for Adminit

```ruby
# Sets up user, superadmin, and permissions
include_context "user and permissions adminit"

# Tests both unauthenticated and unauthorized scenarios
include_context "adminit_auth"
```

---

## Model Specs

### Structure

```ruby
require "rails_helper"

RSpec.describe Support::Ticket, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
  end

  describe "associations" do
    it { should belong_to(:created).class_name("Account") }
    it { should have_one(:conversation).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(open: 0, in_progress: 1, finished: 2, reopen_requested: 3, reopened: 4, closed: 5) }
  end

  describe "scopes" do
    describe ".by_status" do
      it "filters by status" do
        open_ticket = create(:ticket, status: :open)
        closed_ticket = create(:ticket, status: :closed)

        expect(Support::Ticket.by_status("open")).to contain_exactly(open_ticket)
      end
    end
  end

  describe "transition methods" do
    describe "#publish!" do
      context "when scheduled" do
        let(:record) { create(:announcement, :scheduled) }

        it "transitions to published" do
          record.publish!
          expect(record).to be_published
          expect(record.published_at).to be_present
        end
      end

      context "when already published" do
        let(:record) { create(:announcement, :published) }

        it "raises InvalidTransition" do
          expect { record.publish! }.to raise_error(Announcement::InvalidTransition)
        end
      end
    end
  end

  describe "destroy protection" do
    context "when draft" do
      it "allows destruction" do
        record = create(:announcement, :draft)
        expect { record.destroy }.to change(Announcement, :count).by(-1)
      end
    end

    context "when published" do
      it "prevents destruction" do
        record = create(:announcement, :published)
        expect { record.destroy }.not_to change(Announcement, :count)
        expect(record.errors[:base]).to be_present
      end
    end
  end
end
```

### Broadcast Specs

```ruby
describe "broadcasts" do
  it "broadcasts to tickets stream on create" do
    expect {
      create(:ticket)
    }.to have_broadcasted_to("tickets")
  end

  it "broadcasts to admin_tickets stream on create" do
    expect {
      create(:ticket)
    }.to have_broadcasted_to("admin_tickets")
  end
end
```

---

## Controller Specs

### Structure

```ruby
require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

RSpec.describe Support::TicketsController, type: :controller do
  let(:account) { create(:account, :verified) }
  let(:ticket) { create(:ticket, created: account) }

  describe "GET #index" do
    subject { get :index }

    context "when not logged in" do
      it "redirects to login" do
        expect(subject).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in" do
      before { login_user(account) }

      it_behaves_like "respond to success"

      it "is authorized" do
        expect { subject }.to be_authorized_to(:index?, :ticket)
          .with(Support::TicketPolicy)
          .with_context(user: account)
      end
    end
  end

  describe "POST #create" do
    subject { post :create, params: { ticket: attributes } }

    let(:attributes) { attributes_for(:ticket) }

    before { login_user(account) }

    it "creates a ticket" do
      expect { subject }.to change(Support::Ticket, :count).by(1)
    end

    it "is authorized" do
      expect { subject }.to be_authorized_to(:create?, a_kind_of(Support::Ticket))
        .with(Support::TicketPolicy)
        .with_context(user: account)
    end
  end
end
```

### Critical Gotchas

**1. Rodauth middleware does NOT run in controller tests**

Without `before_action :require_account`, `current_account` is nil → NoMethodError. Always test the unauthenticated path.

**2. `verify_authorized` fires even when Rodauth redirects at rack level**

This causes `AuthorizationContextMissing`. Fix: the controller must have `before_action :require_account` to halt the chain before `verify_authorized` runs.

**3. Turbo Frame requests**

`ensure_frame_response` before_action redirects before the action body. Test turbo frame actions with:

```ruby
@request.headers["Turbo-Frame"] = "modal"
```

NOT with `headers:` kwarg — controller tests don't support it.

**4. `be_authorized_to` with STI or built-during-action records**

Use `a_kind_of(Class)` for records that don't exist yet:

```ruby
# Record built during the action — can't match exact instance
expect { subject }.to be_authorized_to(:create?, a_kind_of(Support::Ticket))

# Pre-existing record — match exact instance
expect { subject }.to be_authorized_to(:show?, ticket)
```

---

## Adminit Controller Specs

```ruby
require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

RSpec.describe Adminit::TicketsController, type: :controller do
  include_context "user and permissions adminit"

  let(:ticket) { create(:ticket) }

  describe "GET #index" do
    subject { get :index }

    include_context "adminit_auth"

    context "when logged with permissions" do
      before do
        app_permission        # ensure permission exists
        ticket_permission = create(:permission, resource: :ticket, roles: [user.role])
        login_user(user)
      end

      it_behaves_like "respond to success"

      it "is authorized" do
        expect { subject }.to be_authorized_to(:index?, :ticket)
          .with(Adminit::TicketPolicy)
          .with_context(user: user)
      end
    end
  end
end
```

---

## Interactor Specs

### Single Interactor

```ruby
require "rails_helper"

RSpec.describe Announcements::Schedule, type: :interactor do
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

      it "fails with error" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
        expect(result.error).to eq(I18n.t("announcement.transitions.already_published"))
      end
    end
  end
end
```

### Workflow Integration Test

Test the full lifecycle across multiple interactors:

```ruby
RSpec.describe "Ticket Workflow", type: :interactor do
  let(:user) { create(:account) }
  let(:admin) { create(:account, :with_role) }
  let(:ticket) { create(:ticket, created: user) }

  it "handles the full reopen workflow" do
    # 1. Admin takes the ticket
    result = Adminit::Tickets::Take.call(ticket: ticket, account: admin)
    expect(result.success?).to be(true), result.error
    expect(ticket.reload.status).to eq("in_progress")
    expect(ticket.notes.first.body).to include("taken and assigned")

    # 2. Admin finishes the ticket
    result = Adminit::Tickets::Finish.call(ticket: ticket, account: admin)
    expect(result.success?).to be(true), result.error
    expect(ticket.reload.status).to eq("finished")

    # 3. User requests reopen
    result = Support::Tickets::RequestReopen.call(
      ticket: ticket, account: user, body: "It is still broken"
    )
    expect(result.success?).to be(true), result.error
    expect(ticket.reload.status).to eq("reopen_requested")
  end
end
```

---

## Policy Specs

### ActionPolicy Pattern

```ruby
require "rails_helper"

RSpec.describe Adminit::TicketPolicy, type: :policy do
  let(:admin_role) { create(:role, name: "admin") }
  let(:permission) { create(:permission, resource: :ticket, roles: [admin_role]) }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:creator_account) { create(:account, :verified) }
  let(:policy) { described_class.new(ticket, user: admin_account) }

  before { permission }  # Ensure permission exists

  describe "#take?" do
    context "with an unassigned ticket" do
      let(:ticket) { create(:ticket, status: :open, assigned: nil, created: creator_account) }

      it "allows admin to take the ticket" do
        expect(policy).to be_take
      end
    end

    context "when user has no role" do
      let(:regular_user) { create(:account, :verified) }
      let(:ticket) { create(:ticket, status: :open, assigned: nil, created: creator_account) }
      let(:policy) { described_class.new(ticket, user: regular_user) }

      it "denies user from taking the ticket" do
        expect(policy).not_to be_take
      end
    end
  end
end
```

### Policy Matcher Convention

- `expect(policy).to be_take` — tests `#take?`
- `expect(policy).to be_manage` — tests `#manage?`
- `expect(policy).not_to be_update` — tests denial

---

## Job Specs

```ruby
require "rails_helper"

RSpec.describe PublishAnnouncementJob, type: :job do
  let(:announcement) { create(:announcement, :scheduled) }

  describe "#perform" do
    it "publishes the announcement" do
      described_class.perform_now(announcement.id, announcement.scheduled_at.to_i)
      expect(announcement.reload).to be_published
    end

    it "does nothing if announcement not found" do
      expect {
        described_class.perform_now(0, 0)
      }.not_to raise_error
    end

    it "does nothing if timestamp doesn't match (stale job)" do
      described_class.perform_now(announcement.id, 0)
      expect(announcement.reload).to be_scheduled  # unchanged
    end
  end
end
```

---

## Factory Conventions

Factories live in `spec/factories/`. Use traits for states:

```ruby
FactoryBot.define do
  factory :announcement do
    title { "Test Announcement" }
    body { "Test body" }
    association :author, factory: :account

    trait :draft do
      status { :draft }
    end

    trait :scheduled do
      status { :scheduled }
      scheduled_at { 1.hour.from_now }
    end

    trait :published do
      status { :published }
      published_at { Time.current }
    end
  end
end
```

### Account Factory Traits

```ruby
factory :account do
  trait :verified do
    status { "verified" }
  end

  trait :with_role do
    role { association :role }
  end

  trait :superadmin do
    role { association :role, :superadmin }
  end

  trait :with_admin_role do
    with_role
    verified
  end
end
```

---

## Test Pattern Summary

| What to Test | Spec Type | Key Matchers |
|-------------|-----------|-------------|
| Validations, associations | `type: :model` | `validate_presence_of`, `belong_to` |
| State transitions | `type: :model` | `raise_error(InvalidTransition)` |
| Destroy protection | `type: :model` | `change(Model, :count)` |
| Broadcasts | `type: :model` | `have_broadcasted_to` |
| Auth + authorization | `type: :controller` | `redirect_to(rodauth.login_path)`, `be_authorized_to` |
| HTTP responses | `type: :controller` | Shared examples: `"respond to success"`, etc. |
| Interactor success/failure | `type: :interactor` | `be_success`, `be_failure`, `result.error` |
| Workflow lifecycle | `type: :interactor` | Chain of interactor calls with state assertions |
| Permission checks | `type: :policy` | `be_take`, `be_manage`, `be_update` |
| Job idempotency | `type: :job` | `perform_now` with various guard scenarios |
| Enqueued jobs | `type: :interactor` | `have_enqueued_job(JobClass)` |
| Full user flow | `type: :system` | Capybara: `visit`, `fill_in`, `click_button` |

## Rules

- **ALWAYS** run tests via Docker: `docker compose exec -e RAILS_ENV=test rails bundle exec rspec`
- **ALWAYS** include `require Rails.root.join("spec/controllers/shared/responds.rb")` in controller specs
- **ALWAYS** test both authenticated and unauthenticated paths in controller specs
- **ALWAYS** test authorization with `be_authorized_to` in controller specs
- Use `a_kind_of(Class)` for records built during the action, exact record for pre-existing
- Use `@request.headers["Turbo-Frame"] = "modal"` for turbo frame actions (not `headers:` kwarg)
- Policy specs instantiate the policy directly: `described_class.new(record, user: account)`
- Interactor specs call `.call` and check `result.success?` / `result.failure?`
- Job specs test idempotency: missing record, stale timestamp, already-processed state
- Use `before { permission }` to ensure RBAC permission exists before adminit tests
- Test password is `TestConstants::TEST_PASSWORD` — defined in test setup
