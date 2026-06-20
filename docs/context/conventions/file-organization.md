---
kind: context
id: file_organization
version: 1
source_id: pro_rails_docs
source_ref: context/conventions/file-organization.md
domain: tooling
audience: [developer, architect, backend_engineer, frontend_engineer, tester]
topics: [role-base-developer, file-organization, structure]
references: []
stability: stable
---

# File Organization (Pro-Rails)

Where code lives. Applies when architect plans AND when engineers execute.

## App code

| Code Type | Location |
|---|---|
| Models | `app/models/` (namespaced in subdirs, e.g. `support/`) |
| Cross-cutting concerns | `app/models/concerns/` (flat) |
| Model-specific concerns | `app/models/concerns/{model}/` (when a model has 2+) |
| Controllers | `app/controllers/` (`adminit/`, `support/`, `settings/` namespaces) |
| Controller concerns | `app/controllers/concerns/` |
| Interactors | `app/interactors/{domain}/` |
| Policies | `app/policies/` (mirrors controller structure) |
| Jobs | `app/jobs/` |
| Services (external APIs, pipelines) | `app/services/` |
| Notifiers (Noticed) | `app/notifiers/` |
| Custom delivery methods | `app/notifiers/delivery_methods/` |
| ViewComponents | `app/components/` (`core/` for primitives, domain folders for composed) |
| Views | `app/views/{controller_path}/` |
| Shared partials | `app/views/partials/` |
| Mailers | `app/mailers/` |

## JavaScript

| Code Type | Location |
|---|---|
| Stimulus controllers | `app/javascript/controllers/` |
| Plain JS classes (testable logic) | `app/javascript/models/` |
| Icon animation modules | `app/javascript/icons/` |
| Shared JS utilities | `app/javascript/library/` |

## Config & misc

| Code Type | Location |
|---|---|
| Typed config classes (Anyway Config) | `config/configs/` |
| Locales | `config/locales/{en,es}/{domain}.yml` |
| Rodauth config | `app/misc/rodauth_main.rb`, `app/misc/rodauth_app.rb` |

## Tests

| Code Type | Location |
|---|---|
| Specs | `spec/{models,controllers,interactors,jobs,policies,requests,system}/` |
| Factories | `spec/factories/` |
| Component previews (Lookbook) | `test/components/previews/` |

## Naming hints

- Namespaces in code = subdirectories (`Support::Ticket` → `app/models/support/ticket.rb`)
- Policies mirror controllers (`Adminit::TicketsController` → `app/policies/adminit/ticket_policy.rb`)
- Interactors named by action (`Tickets::Assign`, `Announcements::Schedule`) — verb-first, domain-namespaced
