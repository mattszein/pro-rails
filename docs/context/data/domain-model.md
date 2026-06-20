---
kind: context
id: domain_model
version: 2
source_id: pro_rails_docs
source_ref: context/data/domain-model.md
domain: domain
audience: [backend_engineer, frontend_engineer]
topics: [domain-model, entities, aggregates, identity, support, content]
references: []
stability: stable
---

# Domain Model (Pro-Rails)

Three aggregates: **Identity & Access**, **Content**, **Support**.

## Diagram

```
┌──── Identity & Access ────┐
│ Account ─has_one─▶ Profile │
│   │                        │
│   ├─belongs_to (opt)─▶ Role│
│   │                    │   │
│   │              HABTM │   │
│   │                    ▼   │
│   └─has_many Notifications │
│       (Noticed, polymorphic)│
│                  Permission │
└────────────────────────────┘

┌──── Content ──────────────┐
│ Announcement ─belongs_to─▶ │
│   Account (as author)      │
│   has_rich_text :rich_body │
└────────────────────────────┘

┌──── Support ──────────────┐
│ Support::Ticket            │
│   ├─belongs_to─▶ Account (created)  │
│   ├─belongs_to─▶ Account (assigned) │
│   ├─has_one─▶ Conversation          │
│   │             └─has_many─▶ Message ─▶ Account │
│   ├─has_many─▶ Note (kind: internal/system)     │
│   └─has_many_attached Attachments               │
└─────────────────────────────────────────────────┘
```

## Identity & Access

| Model | Purpose | Key Relationships |
|---|---|---|
| `Account` | User identity (email, status, role). Includes Rodauth. | `belongs_to :role` (optional), `has_one :profile`, `has_many :notifications` via `Account::Notifiable` |
| `Profile` | Display info: avatar (with variants), username, bio | `belongs_to :account` |
| `Role` | Named group of permissions. `superadmin` is RESERVED. | `has_many :accounts`, `has_and_belongs_to_many :permissions` |
| `Permission` | Per-resource access gate. Integer-backed in `Permission::RESOURCE_REGISTRY`. | `has_and_belongs_to_many :roles` |

Account status lifecycle: `unverified → verified → closed`.

## Content

| Model | Purpose | Key Relationships |
|---|---|---|
| `Announcement` | Admin broadcast to all verified accounts. ActionText body. | `belongs_to :author` (Account), `has_rich_text :rich_body` |

Announcement lifecycle: `draft → scheduled → published`.
- Only `draft` is destroyable.
- `published` cannot be edited.

## Support

| Model | Purpose | Key Relationships |
|---|---|---|
| `Support::Ticket` | User-initiated request. TWO Account FKs: creator and assignee. | `belongs_to :created` (Account), `belongs_to :assigned` (Account, optional), `has_one :conversation`, `has_many :notes`, `has_many_attached :attachments` |
| `Support::Conversation` | Message thread for a Ticket | `belongs_to :ticket`, `has_many :messages` |
| `Support::Message` | Message in a Conversation, authored by an Account. Broadcasts on create. | `belongs_to :conversation`, `belongs_to :account` |
| `Support::Note` | Admin-visible note on a Ticket. Kinds: `internal` (admin wrote) and `system` (audit trail by interactors). | `belongs_to :ticket`, `belongs_to :account` (optional — system notes have none) |

Ticket lifecycle:

```
open → in_progress → finished → closed
                  ↘ reopen_requested → reopened → (back to in_progress)
                                     → closed (if rejected)
```

## Cross-cutting

| Concept | Where |
|---|---|
| `Account::Notifiable` concern | `app/models/concerns/account/notifiable.rb` — mixes `has_many :notifications` (Noticed) into Account |
| `Noticed::Notification` | Polymorphic delivery records attached to Accounts. Not a pro-rails model, but part of the domain surface. |

## Key invariants

| Invariant | Why |
|---|---|
| An Account can be BOTH a Ticket creator AND assignee (different tickets) | Two distinct FKs on Ticket |
| Roles ↔ Permissions is many-to-many | One role grants many resources; one resource-permission grants to many roles |
| `Permission::RESOURCE_REGISTRY` integers MUST NEVER be reused | Stored by integer in the join table. Reuse silently changes existing grants. |
| `Support::*` models use simple table names (`tickets`, `conversations`, `messages`, `support_notes`) | Namespace lives in Ruby, not in the schema. `support_notes` is the exception (collision avoidance with future global `notes`). |
| `Role` named `superadmin` is reserved | Bypass / fallback grant — never delete, never rename |
