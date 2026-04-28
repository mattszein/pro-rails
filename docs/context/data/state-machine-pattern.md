---
kind: context
id: state_machine_pattern
version: 1
source_id: pro_rails_docs
source_ref: context/data/state-machine-pattern.md
domain: domain
audience: [backend_engineer]
topics: [state-machine, transitions, lifecycle, enums]
references: [model_rules, side_effect_discipline]
stability: stable
---

# State Machine Pattern (Pro-Rails)

Hand-rolled state machines using Rails enums. No AASM or state_machines gem.

## Shape

Three moving parts per state machine:

1. **Enum-backed status** — integer enum in the DB, human labels in Ruby
2. **Transition method** — raises `InvalidTransition` on bad state; `update!` on success
3. **Query method** — pure read predicate for UI guards

```ruby
enum :status, { draft: 0, scheduled: 1, published: 2 }

def schedule!(at:)
  raise InvalidTransition, t("announcement.transitions.must_be_draft") unless draft?
  update!(status: :scheduled, scheduled_at: at)
end

def editable? = !published?
```

## Per-model `InvalidTransition`

Every model with a state machine defines its own exception class:

```ruby
class Announcement < ApplicationRecord
  class InvalidTransition < StandardError; end
end
```

This lets Interactors rescue specifically (`rescue Announcement::InvalidTransition`) without catching every StandardError. Other exceptions bubble to the error tracker.

## Query methods

Pure read, no side effects. Named for what they enable: `editable?`, `destroyable?`,
`messageable?`. UI uses BOTH policy (can this USER do it?) AND query method (can this
RECORD have it done?). Both must agree for the action to appear.

## `status_was` timing rule

Inside `before_validation` or `before_save`, `status` is already the NEW value.
Use `status_was` to check the previous state:

```ruby
def cannot_update_when_published
  errors.add(:base, "...") if status_was == "published"
end
```

## Destroy guard

Double-layer protection: UI hides the button (query method), callback is the safety net for console / API:

```ruby
before_destroy :ensure_destroyable

def ensure_destroyable
  return if draft?
  errors.add(:base, t("announcement.errors.only_draft_deletable"))
  throw(:abort)
end
```

## I18n strategy

State machines produce two kinds of errors; each goes to a different locale location:

| Error type | Locale location | Example |
|---|---|---|
| Validation errors (AR) | `activerecord.errors.models.<model>.attributes.*` | `activerecord.errors.models.announcement.attributes.status.*` |
| Transition errors (`InvalidTransition`) | `<model>.transitions.*` | `announcement.transitions.must_be_draft` |

Keep them separate. Validation errors render via `model.errors`. Transition errors are caught by Interactors and forwarded via `context.fail!(error: e.message)`.
