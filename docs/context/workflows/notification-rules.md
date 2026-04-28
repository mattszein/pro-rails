---
kind: context
id: notification_rules
version: 2
source_id: pro_rails_docs
source_ref: context/workflows/notification-rules.md
domain: application
audience: [backend_engineer]
topics: [notifications, noticed, delivery]
references: [interactor_rules, job_rules, realtime_broadcasting]
stability: stable
---

# Notification Rules (Pro-Rails)

Noticed gem. Notifiers live in `app/notifiers/`. Custom delivery methods in `app/notifiers/delivery_methods/`.

## Rules

| Rule | Why |
|---|---|
| Trigger from Interactors, NEVER from models | Models don't know request context (locale, recipient prefs, IP) |
| Bulk delivery → enqueue a fan-out job, not inline loop | A 10K-recipient notification cannot block the web request |
| Bulk delivery jobs MUST be idempotent | Query already-notified recipients before delivering |
| One Notifier per logical event (`AnnouncementNotifier`, `TicketAssignedNotifier`) | Clear audit trail and per-event delivery config |

## Notifier shape

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
    def title             = t(".title")
    def subtitle          = record.title
    def notification_type = "announcement"
  end
end
```

## Triggering

| Volume | Pattern |
|---|---|
| Single recipient | Inline `deliver` from Interactor |
| Bulk (many recipients) | Enqueue background fan-out job |

```ruby
# Single
AnnouncementNotifier.with(record: announcement, message: "...").deliver(account)

# Bulk
BulkAnnouncementNotificationJob.perform_later(announcement.id)
```

## Custom delivery methods

`app/notifiers/delivery_methods/turbo_stream.rb` ships with the project — pushes a notification into a stream subscribed by the recipient's layout. Add Slack/SMS/etc. as new files in the same folder.

## Mailers

Three mailer patterns in this project:

- **Noticed-driven** (`AccountMailer`): Triggered by Notifiers. Method called by `deliver_by :email`. Standard ActionMailer subclass.
- **Rodauth instance-allocation** (`RodauthMailer`): Rodauth allocates the mailer directly — DO NOT rename or restructure. Override only the view templates.
- **I18n in subject/body**: Always explicit `I18n.t(...)` keys. Locale at delivery time is set by the job context, which may NOT match the recipient's locale. Always pass `locale:` explicitly from the Interactor that triggers delivery.

## Trap

Triggering `Notifier.deliver` from a model callback. Locale at delivery time is whatever Rails has set (often wrong: a job context doesn't have the recipient's locale). Always trigger from Interactors with explicit locale parameter where applicable.
