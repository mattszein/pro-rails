---
kind: context
id: authentication_rodauth
version: 2
source_id: pro_rails_docs
source_ref: context/auth/authentication-rodauth.md
domain: auth
audience: [backend_engineer]
topics: [authentication-rodauth, authentication, rodauth, account, identity]
references: [explicit_context_passing]
stability: stable
---

# Authentication (Rodauth)

Rodauth handles auth. Configured in `app/misc/rodauth_main.rb` and `app/misc/rodauth_app.rb`.

## Account lifecycle

```
unverified → verified → closed
```

| Status | Meaning |
|---|---|
| `unverified` | Account created, email not yet verified |
| `verified` | Email verified, active |
| `closed` | Closed by user or admin (permanent) |

## Access patterns

| What | How |
|---|---|
| Current user in controller/view | `current_account` |
| Require login on a controller | `before_action :require_account` |
| Request context into interactors | See `explicit-context-passing`. Pass as keyword args; never use `CurrentAttributes`. |

## Trap

Without `before_action :require_account`, `current_account` is `nil` inside the action — Rodauth's rack middleware does NOT halt the chain on its own. Every authenticated controller MUST declare it explicitly. ApplicationController doesn't add it because some controllers (public landing, Rodauth pages) need to be open.
