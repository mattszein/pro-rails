---
kind: skill
id: place_by_layer
version: 1
source_id: pro_rails_docs
source_ref: skills/principle/place_by_layer.md
domain: architecture
audience: [architect, backend_engineer, frontend_engineer]
topics: [principle, placement, layers]
applies_to_roles: [architect, backend_engineer, frontend_engineer]
requires_context_topics: [four-layer-architecture]
stability: stable
---

# Place by Layer

Decide which layer owns a piece of logic.

## Tree

```
Input/transport/rendering?     → Presentation
Authorization check?           → Domain policy (called from Presentation)
Orchestrates 2+ entities OR
  has side effects?            → Application
Single-entity rule/invariant?  → Domain
External system / persistence? → Infrastructure (triggered by Application)
Cross-cutting (logs, metrics)? → Infrastructure (wired at edges)
```

Stop at first match. If unclear → Open Question, don't force.

## Dependency rule

Higher → lower. Never reverse.
- Domain MUST NOT know Presentation.
- Application MUST NOT import Presentation.
- Infrastructure MUST NOT contain business rules.

## Smells

| Smell | Fix |
|---|---|
| Side effect inside Domain callback | Move to Application |
| Business rule inside Controller | Move to Domain or Application |
| HTTP context inside Domain | Pass explicitly from Presentation |
| Job/email/external call from Model | Move to Interactor |
