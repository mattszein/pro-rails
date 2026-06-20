---
kind: context
id: ruby_rails_conventions
version: 2
source_id: pro_rails_docs
source_ref: context/conventions/ruby-rails-conventions.md
domain: tooling
audience: [developer, architect, backend_engineer, frontend_engineer, tester]
topics: [role-base-developer, ruby, rails, conventions]
references: [explicit_context_passing]
stability: stable
---

# Ruby & Rails Conventions (Pro-Rails)

## Rules

| Rule | Why |
|---|---|
| `:unprocessable_content` — NOT `:unprocessable_entity` | Rack deprecated the old name |
| NO `frozen_string_literal: true` magic comment | Freezolite handles it repo-wide automatically |
| Standard Ruby is the linter (`bin/rubocop`) | No bikeshedding style in PRs — run the formatter |
| `status_was` (NOT `status`) inside validations/callbacks checking previous value | At that point `status` is already the new value |
| Integer enum values in `Permission::RESOURCE_REGISTRY` MUST NEVER be reused | Permissions stored by integer in the join table — reuse silently breaks existing grants |
| Always add new permission keys at the END | Same reason — preserves existing integer mapping |
| Pass request context explicitly | See `explicit-context-passing`. Never use `CurrentAttributes` or thread-locals. |

## `status_was` example

```ruby
# WRONG — `status` is already the new value here
def cannot_update_when_published
  errors.add(:base, "...") if status == "published"
end

# RIGHT
def cannot_update_when_published
  errors.add(:base, "...") if status_was == "published"
end
```

## Permission registry trap

```ruby
# Permission::RESOURCE_REGISTRY
{
  account: 0,
  ticket:  1,
  # NEVER: { account: 0, ticket: 2 }   ← removed and reused = silent breakage
}
```

A row in `permissions_roles` storing `resource: 1` was a `ticket` grant. Reuse `1` for `announcement` later → every existing ticket grant becomes an announcement grant. Always append.

## Configuration

Typed config classes live in `config/configs/` using Anyway Config. Each config class is a singleton accessed via `delegate_missing_to`.

```ruby
class FileUploadConfig < ApplicationConfig
  attr_config max_size: 10.megabytes,
              max_count: 5,
              allowed_types: %w[image/jpeg image/png]
end
```

Key patterns:
- `attr_config` sets defaults; ENV variables override at runtime
- Computed methods (e.g., `storage_configured?`) are plain Ruby methods on the config class
- Models reference config classes for limits (`FileUploadConfig.max_size`) instead of hardcoding constants
- Readiness checks (e.g., `storage_configured?`) called from initializers to catch misconfigured deploys early
