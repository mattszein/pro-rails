---
kind: context
id: four_layer_architecture
version: 1
source_id: pro_rails_docs
source_ref: context/four-layer-architecture.md
domain: architecture
audience: [architect, backend_engineer, frontend_engineer]
topics: [four-layer-architecture, architecture, layers]
references: [explicit_context_passing]
stability: stable
---

# Four-Layer Architecture (Pro-Rails)

```
Presentation → Application → Domain → Infrastructure
```

## Layer ownership

| Layer | Owns | Does NOT own |
|---|---|---|
| Presentation | HTTP, params, rendering, channels, views, components, mailers | Business logic, direct DB queries |
| Application | Orchestration, authorization checks, notifications | Persistence, rendering |
| Domain | Business rules, validations, associations, transitions | HTTP context, request objects |
| Infrastructure | AR, external APIs, file storage, caching | Business rules, presentation |

## Mapping

| Layer | Implementation |
|---|---|
| Presentation | Controllers, ViewComponents, views, Stimulus, Turbo Frames, Channels, Mailers |
| Application | Interactors, Policies (ActionPolicy), Notifiers (Noticed) |
| Domain | Models (validations, transitions, scopes, concerns), Query Objects |
| Infrastructure | ActiveRecord, Service Objects, Jobs (Solid Queue), Anyway Config |

## Pattern selection

| Scenario | Pattern | Layer |
|---|---|---|
| Simple CRUD, no side effects | Controller + Model | Presentation + Domain |
| State change + side effects | Interactor | Application |
| Multiple models affected | Interactor | Application |
| External API call | Service Object | Infrastructure |
| Complex/reusable query | Query Object or Scope | Domain |
| Authorization | Policy (ActionPolicy) | Application |
| Notifications | Notifier via Interactor | Application |
| Background work | Job (Solid Queue) | Infrastructure |
| Real-time CRUD sync | `broadcasts_to` in Model | Domain |
| Bidirectional real-time | ActionCable Channel | Presentation |
| Multi-step content processing | Pipeline (CoR) | Infrastructure |
| Typed config | Anyway Config | Infrastructure |

## Business logic split

| Layer | Question |
|---|---|
| Model | "Is this data valid? Is this transition legal?" |
| Controller | "Can this user attempt this action?" |
| Interactor | "What sequence must happen?" |

## Rules

- Lower layers MUST NOT depend on higher layers.
- Solid Queue is in a SEPARATE database. `perform_later` is NOT in app TX.
- See `explicit-context-passing`. Pass request context as keyword args; never use `CurrentAttributes`.
- Validations live in models — last line of defense, fire from any caller.
