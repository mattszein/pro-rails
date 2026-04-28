---
kind: context
id: interactor_rules
version: 2
source_id: pro_rails_docs
source_ref: context/workflows/interactor-rules.md
domain: application
audience: [backend_engineer]
topics: [interactors, application-layer, workflows, transactions]
references: [model_rules, job_rules, notification_rules, explicit_context_passing, side_effect_discipline]
stability: stable
---

# Interactor Rules (Pro-Rails)

Application layer. Owns "what sequence of things must happen." Uses the Interactor gem.

## Structure

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
  end
end
```

## Rules

| Rule | Why |
|---|---|
| Rescue ONLY domain errors (`InvalidTransition`, `ActiveRecord::RecordInvalid`) | Code bugs (NoMethodError, etc) must bubble to error tracker. Don't swallow them. |
| Wrap multi-model writes in `transaction` ONLY when same database | Solid Queue is in a SEPARATE DB (see below) |
| Pass request context (IP, UA, locale) explicitly | See `explicit-context-passing`. Never use `CurrentAttributes`. |
| 2–3 steps → single Interactor | Simpler |
| 4+ reusable steps with rollback logic → `Interactor::Organizer` | Earns its weight |

## Side effects

See `side-effect-discipline`. All side effects (jobs, emails, API calls, conditional broadcasts) live in Interactors — never in models. Models own data integrity; Interactors own orchestration.

## CRITICAL: Solid Queue separate database

`perform_later` is NOT part of the app's transaction, even if called inside `transaction do ... end`. Solid Queue uses a SEPARATE database.

```ruby
ActiveRecord::Base.transaction do
  announcement.update!(status: :scheduled)
  PublishAnnouncementJob.perform_later(...)   # ← NOT in TX
end
# If the TX rolls back, the job was still enqueued.
# If enqueue fails after the state change commits, state change WINS.
```

Mitigation: rely on safety-net recurring jobs to catch missed enqueues for critical flows. See `job-rules`.

## Trap

Adding `rescue StandardError` to an Interactor swallows real bugs. Stay specific to domain errors. If something unexpected happens, let it crash and reach the tracker.
