---
kind: context
id: side_effect_discipline
version: 1
source_id: pro_rails_docs
source_ref: context/workflows/side-effect-discipline.md
domain: architecture
audience: [backend_engineer]
topics: [side-effect-discipline, side-effects, callbacks, interactors]
references: [model_rules, interactor_rules]
stability: stable
---

# Side-Effect Discipline (Pro-Rails)

## What is a side effect

Observable actions beyond persisting data: enqueuing a job, sending an email, calling an external API, conditional broadcasts. These are NOT side effects: DB writes, counter-cache updates, normalizations, simple CRUD broadcasts (`broadcasts_to`).

## Rule

**Side effects live in Interactors.** Models own: validations, state transitions, query methods, and `broadcasts_to` CRUD sync (see Exception).

This means a model method that calls `perform_later`, triggers a notifier, or calls an external API is always wrong. Those belong in the Interactor that calls the model.

## Callback scoring (1–5)

Score every callback when you encounter one. Keep 3–5. Extract 1–2 to an Interactor.

| Score | Type | Example | Action |
|---|---|---|---|
| 5 | Transformer | `before_validation :normalize_email` | Keep |
| 4 | Normalizer | `before_save :strip_whitespace` | Keep |
| 4 | Counter | `after_create :update_counter_cache` | Keep |
| 3 | Auto-broadcast | `broadcasts_to` (CRUD sync) | Keep |
| 2 | Observer | `after_save :notify_admin` | Extract to Interactor |
| 1 | Operation | `after_create :send_welcome_email` | Extract to Interactor |

## Exception: `broadcasts_to` (score 3)

`broadcasts_to` stays in the model. It's CRUD sync — fires synchronously on the same transaction, delivers server-pushed HTML. No external services, no retries, no request context needed.

Only **conditional** broadcasts (`if`, `unless` in the broadcast logic, routing to different targets based on state) belong in Interactors.

## Decision test

If removing the callback breaks data integrity → keep it in the model.

If it triggers external work (jobs, emails, HTTP) or relies on request context (locale, actor identity) → extract it to an Interactor.

## Where each side effect lives

| Side effect | Owner |
|---|---|
| Notifications (Noticed) | Interactor — never models |
| Background jobs | Interactor |
| Conditional broadcasts | Interactor (`Turbo::StreamsChannel.broadcast_*`) |
| External API calls | Interactor (calling a Service Object) |
| CRUD sync broadcasts | Model (`broadcasts_to`) |
