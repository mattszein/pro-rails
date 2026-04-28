---
kind: context
id: support_ticket_system
version: 1
source_id: pro_rails_docs
source_ref: context/support/support-ticket-system.md
domain: support
audience: [backend_engineer, frontend_engineer]
topics: [support-ticket-system, support, tickets, conversations]
references: [state_machine_pattern, realtime_broadcasting, interactor_rules]
stability: stable
---

# Support Ticket System (Pro-Rails)

## Lifecycle

```
open → in_progress → finished → closed
              ↘ reopen_requested → reopened → in_progress (accepted)
                                 → closed   (rejected)
```

Six terminal-or-stable states. The reopen sub-flow branches off `finished`: user requests → admin decides.

## All transitions

| Transition | From state | To state | Interactor |
|---|---|---|---|
| `take` | `open` | `in_progress` | `Adminit::Tickets::Take` |
| `leave` | `in_progress` | `open` | `Adminit::Tickets::Leave` |
| `finish` | `in_progress` | `finished` | `Adminit::Tickets::Finish` |
| `reopen` | `finished` | `closed` | `Adminit::Tickets::Reopen` (closes permanently when admin decides not to reopen) |
| `request_reopen` | `finished` | `reopen_requested` | `Support::Tickets::RequestReopen` (user namespace — user-initiated) |
| `accept_reopen` | `reopen_requested` | `reopened` then `in_progress` | `Adminit::Tickets::AcceptReopen` |
| `reject_reopen` | `reopen_requested` | `closed` | `Adminit::Tickets::RejectReopen` |

`accept_reopen` transitions through `reopened` briefly and then immediately to `in_progress` as part of the same Interactor call — it's not a separately observable state.

## `messageable?` guard

Only `in_progress` and `reopened` statuses allow new messages in the conversation. Additionally, the ticket creator is restricted further: they cannot send a message if the ticket is `finished` or `closed`.

The guard is checked at two levels: policy (`allowed_to?(:create?, with: MessagePolicy)`) and model query method (`ticket.messageable?`). Both must pass.

## Two-account FK

`Support::Ticket` has two Account foreign keys:

- `creator_id` → the user who opened the ticket (set on create, immutable)
- `assignee_id` → the admin currently handling it (nullable, changes on `take`/`leave`)

An account can be both a creator (on their own ticket) and an assignee (on another ticket). The FKs are named `created` and `assigned` in the association (`belongs_to :created, class_name: "Account"`).

## Auto-creation of conversation

`Ticket` has an `after_create` callback that calls `create_conversation`. Every ticket has exactly one `Support::Conversation` — it is created automatically. Controllers and Interactors never call `create_conversation` manually.

## Multi-audience broadcasting

The most complex broadcast pattern in the app. A single ticket state change fans out to multiple targets simultaneously:

| Target stream | Audience | What updates |
|---|---|---|
| `tickets` | User dashboard | User's ticket list row |
| `admin_tickets` | Admin index | Admin ticket list row |
| `ticket_{id}` | User show page | Ticket status header + actions |
| `admin_ticket_{id}` | Admin show page | Ticket status header + assignee + actions |
| `admin_ticket_{id}_notes` | Admin show page | System note appended |

Each target gets its own partial. The Interactor calls `Turbo::StreamsChannel.broadcast_*` for each target after the transition. Because audiences differ, the same data is rendered through different partials.

## Note types

`Support::Note` has two kinds:

| Kind | Created by | Visible to |
|---|---|---|
| `system` | Interactors (audit trail) | Both admins and users |
| `internal` | Admin controllers | Admins only |

Interactors create system notes to record state transitions (`"Ticket taken by admin@example.com"`). These form the audit trail — they must always be written in English regardless of the admin's locale, because they are internal records, not user-facing messages.

Admins create `internal` notes via the UI for private team communication (e.g., "checking with billing team"). Views gate on `note.kind == "internal"` combined with a policy check before rendering.

## Attachment validation

Attachments validate against `FileUploadConfig`, not hardcoded constants. Allowed content types, max file size, and max count are configurable without a code deploy. The validation pattern checks content-type, byte_size, and count against the config class. See `model-rules` (Attachments section) for the validation implementation.

## Categories

Tickets have a category enum: `account_access`, `technical_issue`, `billing`, `feature_request`, `other`. Category is set at creation and immutable. Used for routing and reporting — not yet used for permission logic.

## Priority

Admin-only field. Integer 1–5, nullable (no priority until an admin sets it). Set via `Adminit::Tickets::SetPriority` or directly in the update action. Not part of the state machine — priority does not gate transitions.

## Routing shape

The ticket routing follows two separate resource trees — one under the user dashboard scope and one under the admin scope:

- User: `tickets#show`, `tickets#edit`, `tickets#create`, `tickets/messages#create`
- Admin: `adminit/tickets` with member actions `take`, `leave`, `finish`, `reject_reopen`, `accept_reopen`

The `request_reopen` transition lives in the user namespace (`Support::Tickets::RequestReopen` interactor) even though the ticket state change is admin-visible. This is intentional — users initiate the request, admins decide.
