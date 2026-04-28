---
kind: context
id: authorization_actionpolicy
version: 2
source_id: pro_rails_docs
source_ref: context/auth/authorization-actionpolicy.md
domain: auth
audience: [backend_engineer]
topics: [authorization-actionpolicy, authorization, actionpolicy, adminit, rbac, policies]
references: [authentication_rodauth, model_rules]
stability: stable
---

# Authorization (ActionPolicy + Adminit RBAC)

ActionPolicy gem with custom RBAC for the admin area (Adminit).

## Three-layer authorization (Adminit)

| Layer | What it checks | Where |
|---|---|---|
| 1. Account-level gate | "Does this account have ANY admin role?" | `Account#adminit_access?` |
| 2. Controller-level gate | "Block all admin actions if no role" | `before_action :authorize_adminit_access` |
| 3. Policy-level check | "Can this user do THIS action on THIS resource?" | `authorize!` per action/resource |

All three must pass. Skipping layer 2 means a user with no role hits the policy with confusing errors.

## Policy architecture

| Concept | Where it lives |
|---|---|
| Permission grants (role → resources) | `Role` ↔ `Permission` (HABTM) |
| Resource keys, integer-backed | `Permission::RESOURCE_REGISTRY` |
| Per-resource policy class | `app/policies/adminit/{resource}_policy.rb` |
| Policy resource binding | `POLICY_RESOURCE = :ticket` |
| Policy class binding | `self.identifier = :"Adminit::TicketPolicy"` |
| Permission check (memoized per request) | `Role#permitted?` backed by a `Set` of resource keys |

One DB query per request, regardless of how many `authorize!` calls run.

## Two questions, two layers

| Question | Where to answer |
|---|---|
| "Can this USER do this?" | Policy |
| "Can this RECORD have this done?" | Model (query methods like `editable?`, `destroyable?`) |

The UI uses BOTH: policy hides the link if user can't, query method hides it if record can't.

## Adding a new Adminit resource (3 steps)

1. Add to `Permission::RESOURCE_REGISTRY` with a NEW integer (NEVER reuse existing values).
2. Create policy at `app/policies/adminit/{resource}_policy.rb` with `POLICY_RESOURCE` matching the enum key.
3. Set `self.identifier = :"Adminit::{Resource}Policy"` so ActionPolicy resolves it.

See `ruby-rails-conventions` for the integer-reuse rule and why.

## Per-action override

Override individual predicates when actions need different rules:

```ruby
class Adminit::TicketPolicy < ApplicationPolicy
  POLICY_RESOURCE = :ticket
  self.identifier = :"Adminit::TicketPolicy"

  def take?
    manage? && record.assigned.nil? && record.open?
  end
  # All other actions inherit `manage?` from ApplicationPolicy
end
```

## Trap

Forgetting `verify_authorized` at controller class level means a forgotten `authorize!` silently allows access. ALWAYS declare both `before_action :require_account` AND `verify_authorized` together.
