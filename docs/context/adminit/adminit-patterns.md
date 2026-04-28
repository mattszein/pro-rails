---
kind: context
id: adminit_patterns
version: 1
source_id: pro_rails_docs
source_ref: context/adminit/adminit-patterns.md
domain: adminit
audience: [backend_engineer, frontend_engineer]
topics: [adminit-patterns, adminit, admin-panel, rbac]
references: [authorization_actionpolicy, controller_patterns]
stability: stable
---

# Adminit Patterns (Pro-Rails)

Built-in admin panel. No admin gem — plain Rails controllers and ViewComponents under `Adminit::`.

## Three-layer authorization

| Layer | Mechanism | What fails if skipped |
|---|---|---|
| 1. Account-level | `Account#adminit_access?` (checked in `authorize_adminit_access`) | Users without any role reach admin routes |
| 2. Controller-level | `before_action :authorize_adminit_access` (in `Adminit::ApplicationController`) | All admin controllers would be open to any authenticated user |
| 3. Policy-level | `verify_authorized` + `authorize!` per action | Individual resource actions silently allow access without a permission check |

Skip layer 2 and layer 3 checks still run but the user has no role, so `manage?` always returns false → `ActionPolicy::Unauthorized`. This gives confusing errors rather than a clean 403 at the gate.

## `Permission::RESOURCE_REGISTRY`

Integer-backed enum. Maps resource symbol to stable integer value.

```ruby
RESOURCE_REGISTRY = {
  account:      0,
  ticket:       1,
  announcement: 2,
  # NEVER reuse a retired integer
}
```

Rule: integers are **permanent**. If a resource is removed, leave a gap. Reusing an integer silently reassigns all existing role-permission grants to the new resource.

## Policy inheritance: Adminit does NOT inherit from ApplicationPolicy

`Adminit::ApplicationPolicy` is a separate base class from `ApplicationPolicy`. They do not share a hierarchy. This is intentional — adminit policies get `manage?` auto-granted via `default_rule`, while app-level policies use explicit predicate methods.

Don't inherit an Adminit policy from `ApplicationPolicy` or vice versa. The `get_access` check is different.

## `default_rule :manage?` + `alias_rule`

`Adminit::ApplicationPolicy` declares `default_rule :manage?`. Any action without an explicit predicate method falls through to `manage?`. This means:

- `index?`, `show?`, `create?`, `update?`, `destroy?` all resolve to `manage?` unless overridden.
- Use `alias_rule :take?, :leave?, to: :manage?` when multiple non-standard actions share the same check.
- Override individual predicates only when the action needs narrower rules (e.g., `take?` also checks `record.open?`).

## `self.identifier`

Every Adminit policy sets:

```ruby
self.identifier = :"Adminit::TicketPolicy"
```

Without this, ActionPolicy resolves policies by convention (`Ticket` → `TicketPolicy`). That collides with `app/policies/ticket_policy.rb` if one exists. The explicit identifier prevents ambiguity.

## Superadmin bypass

Current pattern (fragile — flag when extending):

```ruby
def manage?
  return true if user.role&.name == "superadmin"
  user.role&.permitted?(POLICY_RESOURCE)
end
```

The superadmin check is a string comparison against a reserved role name. If the role name changes or the `superadmin` role is deleted, the bypass silently stops working. This is a known fragility — do not move or rename the role.

## Adding a new Adminit resource

1. Add to `Permission::RESOURCE_REGISTRY` with the NEXT integer in sequence. Never reuse retired values.
2. Create `app/policies/adminit/{resource}_policy.rb`:
   - `POLICY_RESOURCE = :resource_key` (matches registry key)
   - `self.identifier = :"Adminit::{Resource}Policy"` (prevents name collision)
   - Inherit from `Adminit::ApplicationPolicy`
3. Create controller inheriting from `Adminit::ApplicationController`:
   - `before_action :authorize_adminit_access` is inherited
   - Add `verify_authorized` at class level
   - Call `authorize! record` in each action
4. Add routes inside `draw :adminit` block (`config/routes/adminit.rb`)
5. Add I18n keys under `adminit.*` namespace in both `en/adminit.yml` and `es/adminit.yml`

## Menu helper

The adminit layout uses a menu helper that resolves permitted menu items for the current
user by checking `allowed_to?(:manage?, with: policy_class)` for each resource in the
registry. Use this rather than iterating `allowed_to?` manually in views — it handles
missing roles and empty permission sets gracefully.

## I18n for Adminit

All admin-facing strings live under the `adminit.*` I18n namespace:
- Flash messages: `adminit.tickets.taken`, `adminit.accounts.deleted`, etc.
- Error messages: `adminit.errors.*`
- Labels: `adminit.{resource}.{attribute}`

Use `adminit.*` flash keys (`flash[:adminit_notice]`) to avoid colliding with user-facing
flash messages rendered in the dashboard layout. Both layouts render their own flash
containers — an `adminit_notice` on a user page goes unseen, which is the correct behavior.
