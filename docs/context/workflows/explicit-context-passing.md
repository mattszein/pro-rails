---
kind: context
id: explicit_context_passing
version: 1
source_id: pro_rails_docs
source_ref: context/workflows/explicit-context-passing.md
domain: application
audience: [backend_engineer]
topics: [explicit-context-passing, request-context, current-attributes]
references: []
stability: stable
---

# Explicit Context Passing (Pro-Rails)

## Rule

No `CurrentAttributes`. No thread-locals. Request context travels as explicit keyword
arguments from the edge to wherever it's needed.

## The chain

Controller reads from the request and passes down:

```ruby
Tickets::Assign.call(
  ticket: @ticket,
  assignee: account,
  ip_address: request.remote_ip,
  locale: I18n.locale
)
```

Interactor receives and delegates:

```ruby
delegate :ticket, :assignee, :ip_address, :locale, to: :context
```

Interactor to job (primitives only — not AR objects):

```ruby
PublishAnnouncementJob.perform_later(announcement.id, I18n.locale.to_s)
```

## Why

- **Testability:** Call any interactor or service directly in tests with any locale or IP — no test setup of thread state.
- **Thread safety:** Puma runs concurrent threads. `CurrentAttributes` resets between requests unpredictably in concurrent environments.
- **Traceable:** Reading the call chain tells you exactly what context each layer received.

## What NOT to do

```ruby
Current.account = current_account   # WRONG — CurrentAttributes
Thread.current[:locale] = I18n.locale  # WRONG — thread-local
```

Both patterns fail in job contexts, system tests, and concurrent request handling.
