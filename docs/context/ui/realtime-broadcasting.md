---
kind: context
id: realtime_broadcasting
version: 2
source_id: pro_rails_docs
source_ref: context/ui/realtime-broadcasting.md
domain: presentation
audience: [backend_engineer, frontend_engineer]
topics: [realtime, turbo-streams, actioncable, anycable, broadcasts]
references: [model_rules, interactor_rules]
stability: stable
---

# Real-Time Architecture (Pro-Rails)

AnyCable replaces ActionCable. Same API surface, higher performance.

## Broadcasting decision

| Scenario | Where to broadcast |
|---|---|
| Simple CRUD sync | Model (`broadcasts_to`) |
| Workflow with notifications | Interactor |
| Conditional broadcasts | Interactor |
| User-specific broadcasts | Interactor or Controller |

## Channel decision

One channel per concern. NEVER route multiple features through a single channel with type flags.

| Mechanism | When |
|---|---|
| Turbo Streams (`broadcasts_to`) | Server pushes HTML. CRUD. One-directional. |
| Custom ActionCable Channel | Client sends AND receives. Typing indicators, presence, live cursors. |

## Model-level (CRUD sync)

```ruby
class Support::Ticket < ApplicationRecord
  broadcasts_to ->(ticket) { "tickets" }, partial: "support/tickets/ticket_table"

  after_create_commit do |ticket|
    broadcast_append_later_to "admin_tickets",
      target: "admin_tickets",
      partial: "adminit/tickets/ticket_row"
  end
end
```

## Interactor-level (workflow / conditional)

```ruby
def call
  ticket.assign!(assignee)
  Turbo::StreamsChannel.broadcast_replace_to(
    "ticket_#{ticket.id}",
    target: ActionView::RecordIdentifier.dom_id(ticket, "header"),
    partial: "support/tickets/header",
    locals: { ticket: ticket }
  )
end
```

## Rules

| Rule | Why |
|---|---|
| `dom_id` is NOT available in model context | Use `ActionView::RecordIdentifier.dom_id(record, "prefix")` explicitly |
| Broadcasts are locale-neutral | Broadcast DATA, not translated labels. Subscriber view translates on render. |
| Don't put conditional logic in `broadcasts_to` | Conditional broadcasts → move to Interactor. See `side-effect-discipline`. |
| Don't share a channel across features | One concern per channel — debugging routing across features is painful |

## Trap

Putting a conditional broadcast in a model callback (`after_save :maybe_broadcast`) leaks workflow logic into the Domain layer AND fires from Console/Tests/Seeds where you don't want it. Move it to the Interactor.
