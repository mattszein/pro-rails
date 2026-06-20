---
kind: context
id: announcement_system
version: 1
source_id: pro_rails_docs
source_ref: context/announcements/announcement-system.md
domain: content
audience: [backend_engineer, frontend_engineer]
topics: [announcement-system, announcements, content, actiontext]
references: [state_machine_pattern, interactor_rules, job_rules, notification_rules]
stability: stable
---

# Announcement System (Pro-Rails)

## Lifecycle

```
draft → scheduled → published
      ↑ (unschedule back to draft)
```

Three transitions: `schedule!` (draft → scheduled), `unschedule!` (scheduled → draft), `publish!` (scheduled → published). Published announcements are permanent — no revert.

## Immutability guards

| Validation | When | Effect |
|---|---|---|
| `scheduled_at_immutable_when_scheduled` | `on: :update` | Prevents changing `scheduled_at` after the job is enqueued |
| `cannot_update_when_published` | `on: :update` | Blocks all field edits once published |

Both use `status_was` — see `state-machine-pattern` for the timing rule.

## Destroy guard

`before_destroy :ensure_destroyable` — only `draft` announcements can be deleted. `scheduled` and `published` throw abort. Paired with `destroyable?` query method for UI guard.

## Custom `scheduled_at=` writer

The date/time picker sends a formatted string (`"%m/%d/%Y %I:%M %p"`). A custom attribute writer parses this format:

```ruby
def scheduled_at=(value)
  super(value.is_a?(String) ? Time.strptime(value, "%m/%d/%Y %I:%M %p") : value)
rescue ArgumentError
  super(nil)
end
```

This keeps the model responsible for input normalization, not the controller.

## `before_validation :sync_body_from_rich_body`

ActionText stores rich content separately via `has_rich_text :rich_body`. The `body` column (plain text) is denormalized for search. Before validation, the callback extracts plain text from `rich_body` into `body`. Querying `body` for search/preview is safe without loading the ActionText attachment.

## `PublishAnnouncementJob` staleness guard

The job receives `expected_scheduled_at` (the `scheduled_at.to_i` captured at enqueue time):

```ruby
return if announcement.scheduled_at.to_i != expected_scheduled_at
```

If the user reschedules (`unschedule!` then `schedule!` again), the old job's timestamp no longer matches. The old job no-ops; the new `schedule!` call enqueues a fresh job with the current timestamp.

## `BulkAnnouncementNotificationJob` fan-out

When an announcement is published, `Announcements::Publish` Interactor calls:
1. `announcement.publish!` (transition)
2. `BulkAnnouncementNotificationJob.perform_later(announcement.id)` — enqueued to Solid Queue (separate DB, outside the app transaction)

The bulk job iterates `Account.verified.find_each` and enqueues one `AnnouncementNotificationJob` per account. Per-recipient jobs carry their own existence guard.

## ActionText

`has_rich_text :rich_body` — stored in `action_text_rich_texts` table, not on `announcements`. Loading the announcement does NOT eager-load the rich body by default. Add `.with_rich_text_rich_body` or `.with_all_rich_text` to scopes that need it.
