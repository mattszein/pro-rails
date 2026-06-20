---
kind: context
id: job_rules
version: 2
source_id: pro_rails_docs
source_ref: context/infrastructure/job-rules.md
domain: infrastructure
audience: [backend_engineer]
topics: [jobs, solid-queue, idempotency, infrastructure]
references: [interactor_rules, explicit_context_passing]
stability: stable
---

# Background Job Rules (Pro-Rails)

Infrastructure layer. Solid Queue. PostgreSQL-backed, SEPARATE database from the app.

## Rules

| Rule | Why |
|---|---|
| Jobs MUST be idempotent — safe to run multiple times | Cross-DB enqueue, retries, redelivery — exactly-once is impossible |
| Two guards: record exists + expected-state matches | Detect deleted records and stale runs |
| Do NOT add redundant state guards | `model.publish!` already raises `InvalidTransition` if state is wrong. Duplication leaks domain rules into infrastructure. |
| Critical jobs need a recurring safety net | Catches missed enqueues from cross-DB boundary |
| Accept primitive arguments only (`id`, `timestamp.to_i`) | NOT AR objects — GlobalID re-fetches and defeats expected-state guarding |
| `find_by(id:)` not `find` | A deleted record must be a silent no-op, not RecordNotFound |
| Delegate work to an Interactor | Job's job is dispatch, not domain logic |
| Log domain failures, do NOT raise | Domain failures aren't retryable. Infra failures bubble to `retry_on` |
| Pass locale/IP explicitly if needed | See `explicit-context-passing`. No thread-locals in job context. |

## The two guards

```ruby
def perform(announcement_id, expected_scheduled_at)
  announcement = Announcement.find_by(id: announcement_id)
  return unless announcement                                       # Guard 1: existence
  return if announcement.scheduled_at.to_i != expected_scheduled_at # Guard 2: expected-state

  result = Announcements::Publish.call(announcement: announcement)
  Rails.logger.error("PublishJob Failed for #{announcement_id}: #{result.error}") if result.failure?
end
```

## Choosing the expected-state value

| Bad choice | Why |
|---|---|
| The field the job is about to change (e.g. `status`) | After a successful run, retry sees the new value, exits as if stale. Masks success as miss. |
| `record.id` | Never changes — guard is meaningless |
| Volatile fields (e.g. `title`) | Changes for irrelevant reasons — job becomes flaky |

| Good choice | Why |
|---|---|
| Timestamp captured at enqueue (`scheduled_at.to_i`) | Changes when user reschedules — stale job no-ops correctly |
| Version number | Increments on relevant updates only |
| Explicit `expected_state` parameter | Caller decides what staleness means |

## Standard shape

```ruby
class PublishAnnouncementJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(announcement_id, expected_scheduled_at)
    # ... two guards, delegate to interactor, log on failure
  end
end
```

## Bulk fan-out

For many recipients, enqueue ONE fan-out job that enqueues per-recipient jobs. Don't loop and `deliver` inline.

```ruby
class BulkAnnouncementNotificationJob < ApplicationJob
  def perform(announcement_id)
    announcement = Announcement.find_by(id: announcement_id)
    return unless announcement
    return unless announcement.published?  # Reader, not writer — OK to use status

    Account.verified.find_each do |account|
      AnnouncementNotificationJob.perform_later(account.id, announcement_id)
    end
  end
end
```

Each per-recipient job carries its own guards.

## Trap

Calling `.find` instead of `.find_by`: a deleted record raises `RecordNotFound`, which the `retry_on StandardError` will dutifully retry 3 times. Wasted work + log noise. Always `.find_by(id:)` and `return unless`.
