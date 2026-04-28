---
kind: role
id: developer
version: 1
source_id: pro_rails_docs
source_ref: roles/developer.md
domain: tooling
audience: [developer, architect, backend_engineer, frontend_engineer, tester]
topics: [role-base, developer]
context_tags: [role-base-developer]
stability: stable
---

# Developer (Base Role)

Universal disciplines every dev role inherits from. Architect, backend, frontend, tester all extend this.

## Mindset

- Right tool for right complexity. Pattern only when it earns its weight.
- Single source of truth. Same rule in two places = future drift.
- Explicit over implicit. No hidden magic, no thread-local context.
- Defense in depth. Validations are the last line, even against the console.

## Always

- Match existing project patterns over generic best practice.
- Make decisions visible. Layer placement, naming, ownership — never "figure it out."
- Surface ambiguity as Open Question. Don't force.
- Run linter/formatter before committing. Hooks exist for a reason.

## Never

- `--no-verify` / skip hooks. Fix what they report.
- Abreviate names to save typing. `usr`, `acc`, `tkt` = no.
- Add AI attribution to commits (`Co-Authored-By` etc).
- `CurrentAttributes` or thread-locals for request context. Pass explicitly.
- Reuse integer enum values once shipped.

## Bootstrap

Tag `role-base-developer` brings: docker, i18n, ruby/rails conventions, file organization, git conventions. Every role inheriting from `developer` gets this set automatically.
