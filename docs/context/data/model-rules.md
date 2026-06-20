---
kind: context
id: model_rules
version: 2
source_id: pro_rails_docs
source_ref: context/data/model-rules.md
domain: domain
audience: [backend_engineer]
topics: [models, validations, transitions, callbacks, concerns, sti, enums]
references: [realtime_broadcasting, explicit_context_passing, side_effect_discipline]
stability: stable
---

# Model Rules (Pro-Rails)

Models own the Domain layer. Last line of defense for data integrity — fire from any caller (controller, interactor, job, console, seed).

## File layout inside a model

```
1. Extensions / DSL (has_secure_password, acts_as_*)
2. Associations
3. Enums
4. Normalizations
5. Validations
6. Scopes
7. Callbacks (transformers / normalizers only — score 4–5)
8. Delegations
9. Broadcasting (broadcasts_to)
10. Public methods (queries first, then transitions)
11. Private methods
```

## Validations

- ALWAYS in the model. They fire regardless of caller.
- Use `status_was` (not `status`) when checking previous value in state-based validations. See `ruby-rails-conventions`.

## Transition methods (state changes)

Pure DB operations. **NO side effects** — no jobs, no emails, no API calls, no broadcasts beyond `broadcasts_to` declarations.

```ruby
def publish!
  raise InvalidTransition, t("...must_be_scheduled_first") unless scheduled?
  update!(status: :published, published_at: Time.current)
end
```

Why: keeps models safe in Console / Tests / Seeds. Side effects belong to the Interactor that CALLS the transition. See `side-effect-discipline`.

## Query methods (UI guards)

Pure read methods for visibility checks. NO side effects.

```ruby
def editable?     = !published?
def destroyable?  = draft?
def messageable?  = in_progress? || reopened?
```

## Custom exceptions

One per model with a state machine:

```ruby
class Announcement < ApplicationRecord
  class InvalidTransition < StandardError; end
end
```

Interactors rescue this class specifically. Other errors bubble up to the tracker.

## Destroy protection (defense in depth)

```ruby
before_destroy :ensure_destroyable

def ensure_destroyable
  return if draft?
  errors.add(:base, t("...only_draft_deletable"))
  throw(:abort)
end
```

Pair with a `destroyable?` query method. UI hides the destroy button using the query; the callback is the safety net (covers Console, direct API, etc).

## Callback scoring

See `side-effect-discipline`. Score callbacks 1–5; scores 1–2 extract to Interactor; scores 3–5 stay in the model. `broadcasts_to` is score 3 and stays.

## Concerns

| Scope | Location |
|---|---|
| Cross-cutting (used by 2+ models) | `app/models/concerns/` (flat) |
| Model-specific, single concern | Inline in the model |
| Model-specific, 2+ concerns for same model | `app/models/concerns/{model}/` (subdirectory) |

## Namespacing

| Condition | Approach |
|---|---|
| Multiple related models forming a domain | Namespace (`Support::Ticket`, `Support::Conversation`, `Support::Message`, `Support::Note`) |
| Single standalone model | No namespace (`Announcement`) |
| Model used across multiple domains | No namespace |

Namespaced models use the SIMPLE table name (`tickets`, not `support_tickets`) unless a collision forces otherwise (`Support::Note` → `support_notes` because `notes` might collide later).

## STI vs Enums

| Use STI when | Use Enums when |
|---|---|
| Subtypes have different behavior (callbacks, validations, scopes) | Variants differ in label but follow same workflow |
| Conditional logic around type appears in 3+ places | Number of variants might grow beyond 4–5 |
| Each variant has a meaningful name | No behavioral difference between types |

## Broadcasting from models

Use `broadcasts_to` ONLY for simple CRUD sync. For workflow / conditional broadcasts, use `Turbo::StreamsChannel.broadcast_*` from the Interactor — see `realtime-broadcasting`.

`dom_id` is NOT available in model context. Use `ActionView::RecordIdentifier.dom_id(record, "prefix")`.

## Attachments

`has_many_attached` for file uploads. Validate against a config class (preferred — see `Support::Ticket`) or inline (legacy — see `Profile`).

```ruby
# Preferred: limits from config class
validate :attachment_limits

def attachment_limits
  return unless attachments.attached?
  errors.add(:attachments, "...") if attachments.count > FileUploadConfig.max_count
  attachments.each do |attachment|
    unless FileUploadConfig.allowed_types.include?(attachment.content_type)
      errors.add(:attachments, "...")
    end
    if attachment.byte_size > FileUploadConfig.max_size
      errors.add(:attachments, "...")
    end
  end
end
```

Validate content-type, size, AND count. Never hardcode limits in models — reference the config class.
