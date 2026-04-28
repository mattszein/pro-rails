---
kind: context
id: pagination_strategy
version: 2
source_id: pro_rails_docs
source_ref: context/infrastructure/pagination-strategy.md
domain: infrastructure
audience: [backend_engineer, frontend_engineer]
topics: [pagination, pagy, performance]
references: []
stability: stable
---

# Pagination Strategy (Pro-Rails)

## Decision

| Scenario | Approach |
|---|---|
| Admin tables, moderate data (< 100K) | `pagy` |
| Infinite scroll feeds | `pagy_countless` (skips COUNT query) |
| Chat / messages / audit logs (10K+, real-time inserts) | Cursor-based (`WHERE id < :cursor`) |
| API endpoints | `pagy` with `pagy/extras/headers` |

## Why cursor for high-volume + real-time

`OFFSET` scans and discards rows — O(N) at depth N. Cursor uses the PK index directly — O(1) regardless of depth. Also stable when new rows are inserted between requests (offset shifts; cursor doesn't).

## Standard pagy

```ruby
@pagy, @records = pagy(scope)             # With total count
@pagy, @records = pagy_countless(scope, limit: 20)  # No COUNT
```

## Cursor (model concern)

```ruby
PAGE_SIZE = 50

scope :before_cursor, ->(id) { where("id < ?", id).order(id: :desc).limit(PAGE_SIZE) }
scope :after_cursor,  ->(id) { where("id > ?", id).order(id: :asc).limit(PAGE_SIZE) }
```

## Trap

Defaulting to `pagy` for chat/audit views. At 50K+ rows with frequent inserts, page 200 takes seconds. Use cursor for any append-heavy collection.
