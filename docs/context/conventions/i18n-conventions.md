---
kind: context
id: i18n_conventions
version: 1
source_id: pro_rails_docs
source_ref: context/conventions/i18n-conventions.md
domain: tooling
audience: [developer, architect, backend_engineer, frontend_engineer, tester]
topics: [role-base-developer, i18n, l10n, conventions]
references: []
stability: stable
---

# I18n Conventions (Pro-Rails)

Ships English + Spanish from day one. Every user-facing string MUST exist in BOTH locale files.

## File layout

```
config/locales/
  en.yml / es.yml          ← Model layer: AR errors, enums, transition errors
  en/  es/
    shared.yml             ← Used by 2+ domains
    adminit.yml            ← Admin area
    support.yml            ← Support domain
    settings.yml           ← User settings (profile, appearance)
    rodauth.yml            ← Auth pages
    mailers.yml            ← Email templates
```

## Decision: which file does this key go in?

| Scope of the string | File |
|---|---|
| Used by 2+ domains | `{locale}/shared.yml` |
| Specific to one domain | `{locale}/{domain}.yml` |
| Model-layer (validation errors, enum labels, transition errors) | Root `{locale}.yml` |

## Usage rules

| Rule | Pattern |
|---|---|
| Explicit namespaced keys | `I18n.t("adminit.tickets.updated")` ✅ — never lazy `t(".updated")` ❌ (breaks when partial rendered from another context) |
| Enum display | `t("enums.ticket.status.#{status}")` ✅ — never `.humanize` ❌ (bypasses translation) |
| Form labels | Always explicit `label: t(...)` ✅ — never auto-generated ❌ |
| System notes (audit records by interactors) | English only — not user-facing |
| Turbo broadcasts | Locale-neutral. Broadcast DATA, not translated labels. Subscriber translates on render. |
| Adding any key | Add to BOTH `en/` and `es/`. No exceptions. |

## Trap

Lazy lookup (`t(".x")`) resolves based on the rendering view path. When a partial gets rendered from a different controller, the key resolves wrong (or not at all) and you get `translation missing` in production. Always namespace explicitly.
